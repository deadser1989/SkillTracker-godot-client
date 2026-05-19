    #include "skill_manager.hpp"
    #include <godot_cpp/core/class_db.hpp>
    #include <godot_cpp/variant/utility_functions.hpp>
    #include <godot_cpp/classes/time.hpp>
    #include <godot_cpp/variant/dictionary.hpp>
    #include <algorithm>
    #include <vector>
    #include <godot_cpp/classes/time.hpp>   

    using namespace godot;

    void SkillManager::_bind_methods() {
        ClassDB::bind_method(D_METHOD("load_catalog_from_json", "json"), &SkillManager::load_catalog_from_json);
        ClassDB::bind_method(D_METHOD("roll_rarity"), &SkillManager::roll_rarity);
        ClassDB::bind_method(D_METHOD("roll_new_skill", "parent_area"), &SkillManager::roll_new_skill);
        ClassDB::bind_method(D_METHOD("can_start_new_skill"), &SkillManager::can_start_new_skill);
        ClassDB::bind_method(D_METHOD("request_start_skill"), &SkillManager::request_start_skill);
        ClassDB::bind_method(D_METHOD("get_cooldown_time_left"), &SkillManager::get_cooldown_time_left);
        ClassDB::bind_method(D_METHOD("parse_user_tree", "json_string"), &SkillManager::parse_user_tree);
        ClassDB::bind_method(D_METHOD("get_skill_data", "id"), &SkillManager::get_skill_data);

        ClassDB::bind_method(D_METHOD("calculate_current_streak"), &SkillManager::calculate_current_streak);

        ClassDB::bind_method(D_METHOD("log_action", "skill_id", "progress_added"), &SkillManager::log_action);
        ClassDB::bind_method(D_METHOD("get_action_history"), &SkillManager::get_action_history);

        ClassDB::bind_method(D_METHOD("add_obligation", "node"), &SkillManager::add_obligation);
        ClassDB::bind_method(D_METHOD("get_all_obligations"), &SkillManager::get_all_obligations);

        ADD_SIGNAL(MethodInfo("cooldown_started"));
        ADD_SIGNAL(MethodInfo("cooldown_finished"));
        ADD_SIGNAL(MethodInfo("obligations_updated"));
    }


    SkillManager::SkillManager() {
        set_process(true); 
        UtilityFunctions::randomize();                  //запуск генератора случ чисел
        skill_catalog = Dictionary(); 
        instant_starts_left = MAX_DAILY_STARTS;
        is_on_cooldown = false;
        cooldown_timer_sec = 0.0f;
    }

    SkillManager::~SkillManager() {}


    void SkillManager::load_catalog_from_json(const String& json_string) {
        Ref<JSON> json = memnew(JSON);
        Error err = json->parse(json_string);
        if (err != OK) {
            UtilityFunctions::print("ERROR: ", json->get_error_message());
            return;
        }

        skill_catalog.clear();
        Array skills_array = json->get_data();
        
        for (int i = 0; i < skills_array.size(); i++) {
            Dictionary dict = skills_array[i];
    
            String id_str = String::num_int64((int)dict["id"]);

            skill_catalog[id_str] = dict;
        }

        UtilityFunctions::print("Catalog loaded(esketit)");
    }


    int SkillManager::roll_rarity(){                   //ролл редкости для искмого навыка
        float roll = UtilityFunctions::randf_range(0.0f, 100.0f);

        if (roll <= 4.0f) {
            return SkillNode::RARITY_LEGENDARY;
        }  else if (roll <= 15.0f) {
            return SkillNode::RARITY_EPIC; 
        }  else if (roll <= 50.0f) {
            return SkillNode::RARITY_RARE;
        }  else {
            return SkillNode::RARITY_COMMON;
        }   
    }




    void SkillManager::_process(double delta) { //тик каждый кадр
        if (is_on_cooldown) {
            cooldown_timer_sec -= delta;
            if (cooldown_timer_sec <= 0.0f) {
                cooldown_timer_sec = 0.0f;
                is_on_cooldown = false;
                
                UtilityFunctions::print("30 MINUTE COOLDOWN FINISHED! You can start a new skill.");
                emit_signal("cooldown_finished");
            }
        }
    }


    bool SkillManager::can_start_new_skill() const {
        if (is_on_cooldown) {
            return false;
        }
        return true;
    }

    String SkillManager::roll_new_skill(int parent_area) {
        int target_rarity = roll_rarity();
        PackedStringArray valid_skills;
        Array keys = skill_catalog.keys();

        for (int i = 0; i < keys.size(); i++) {
            Dictionary data = skill_catalog[keys[i]];
            if ((int)data["area"] == parent_area && (int)data["node_rarity"] == target_rarity) {
                valid_skills.append(keys[i]);
            }
        }

        if (valid_skills.size() == 0) {
            for (int i = 0; i < keys.size(); i++) {
                Dictionary data = skill_catalog[keys[i]];
                if ((int)data["area"] == parent_area) valid_skills.append(keys[i]);
            }
        }

        if (valid_skills.size() == 0) return "error";

        int idx = UtilityFunctions::randi() % valid_skills.size();
        return valid_skills[idx];
    }

    bool SkillManager::request_start_skill() {
        if (is_on_cooldown) {
            UtilityFunctions::print("DENIED: You are on cooldown for ", cooldown_timer_sec, " more seconds.");
            return false;
        }

        if (instant_starts_left > 0) {                  //если попытки есть - списываем одну
            instant_starts_left--;
            UtilityFunctions::print("Started skill! Instant starts left today: ", instant_starts_left);
            
            if (instant_starts_left == 0) {             //последняя попытка? запускаем таймер
                is_on_cooldown = true;
                cooldown_timer_sec = COOLDOWN_TIME;
                UtilityFunctions::print("Out of instant starts. 30 min cooldown started NOW.");
                emit_signal("cooldown_started");
            }
            
            return true;                                //разрешщаем ui перевести навык в active
        }

        return false;
    }


    float SkillManager::get_cooldown_time_left() const {
        return cooldown_timer_sec;
    }


    void SkillManager::reset_daily_starts() {
        instant_starts_left = MAX_DAILY_STARTS;
        is_on_cooldown = false;
        cooldown_timer_sec = 0.0f;
        UtilityFunctions::print("New day! Daily starts reset to ", MAX_DAILY_STARTS);
    }


 Array SkillManager::parse_user_tree(const String& json_string) {
    Array parsed_nodes;
    Ref<JSON> json = memnew(JSON);
    
    if (json->parse(json_string) != OK) {
        UtilityFunctions::print("ERROR: Ошибка парсинга JSON дерева!");
        return parsed_nodes;
    }
    
    Variant root_data = json->get_data();
    if (root_data.get_type() != Variant::ARRAY) {
        return parsed_nodes;
    }
    
    Array root_array = root_data;
    if (root_array.size() == 0) return parsed_nodes;

    bool is_django_format = false;
    Dictionary first_elem = root_array[0];
    if (first_elem.has("nodes")) {
        is_django_format = true;
    }

    auto parse_node_dict = [](Dictionary dict, int fallback_area) -> SkillNode* {
        SkillNode* new_node = memnew(SkillNode);
        
        if (dict["id"].get_type() == Variant::INT) {
            new_node->setSkillId(String::num_int64((int)dict["id"]));
        } else {
            new_node->setSkillId(dict["id"]);
        }
        
        new_node->setSkillName(dict.get("node_name", "New Skill"));
        new_node->setSkillTitle(dict.get("node_info", "Description"));
        new_node->setSkillLevel((int)dict.get("node_level", 1));
        new_node->setSkillRarity((int)dict.get("node_rarity", SkillNode::RARITY_COMMON));
        new_node->setSkillXP((int)dict.get("xp_reward", 10));
        
        int area_val = dict.get("area", fallback_area);
        new_node->setSkillSubjectArea(area_val);
        
        new_node->setSkillCurProg((int)dict.get("current_progress", 0));
        
        int target_prog = 1;
        if (dict.has("target_progress")) target_prog = (int)dict["target_progress"];
        else if (dict.has("base_progress")) target_prog = (int)dict["base_progress"];
        
        new_node->set_base_progress(target_prog);
        new_node->refresh_target_by_level();

        Variant cd_val = dict.get("cooldown", "once");
        if (cd_val.get_type() == Variant::INT) {
            new_node->setCooldownType((int)cd_val);
        } else {
            String cooldown_str = cd_val;
            if (cooldown_str == "daily" || cooldown_str == "D") new_node->setCooldownType(SkillNode::CD_DAILY);
            else if (cooldown_str == "weekly" || cooldown_str == "W") new_node->setCooldownType(SkillNode::CD_WEEKLY);
            else if (cooldown_str == "monthly" || cooldown_str == "M") new_node->setCooldownType(SkillNode::CD_MONTHLY);
            else new_node->setCooldownType(SkillNode::CD_ONCE);
        }

        Variant dur_val = dict.get("duration_sec", Variant());
        if (dur_val.get_type() != Variant::NIL && (int)dur_val > 0) {
            new_node->setTaskType(SkillNode::TASK_TIMER);
            new_node->setSkillTime((int)dur_val);
        } else {
            new_node->setTaskType(SkillNode::TASK_MANUAL);
            new_node->setSkillTime(-1);
        }

        Variant state_val = dict.get("node_state", "hidden");
        if (state_val.get_type() == Variant::INT) {
            new_node->setSkillState((int)state_val);
        } else {
            String s_state = state_val;
            if (s_state == "hidden") new_node->setSkillState(SkillNode::STATE_HIDDEN);
            else if (s_state == "revealed") new_node->setSkillState(SkillNode::STATE_REVEALED);
            else if (s_state == "active") new_node->setSkillState(SkillNode::STATE_ACTIVE);
            else new_node->setSkillState(SkillNode::STATE_FINISHED);
        }

        Variant parent_val = dict.get("parent", Variant());
        if (parent_val.get_type() != Variant::NIL) {
            PackedStringArray reqs;
            if (parent_val.get_type() == Variant::INT) {
                reqs.append(String::num_int64((int)parent_val));
            } else {
                reqs.append(parent_val);
            }
            new_node->setRequiredPrevSkills(reqs);
        }
        
        return new_node;
    };

    if (is_django_format) {
        for (int i = 0; i < root_array.size(); i++) {
            Dictionary area_dict = root_array[i];
            int area_id = area_dict.get("area", SkillNode::AREA_CUSTOM);
            Array nodes_array = area_dict.get("nodes", Array());
            
            for (int j = 0; j < nodes_array.size(); j++) {
                Dictionary node_dict = nodes_array[j];
                parsed_nodes.append(parse_node_dict(node_dict, area_id));
            }
        }
    } else {
        for (int i = 0; i < root_array.size(); i++) {
            Dictionary node_dict = root_array[i];
            parsed_nodes.append(parse_node_dict(node_dict, SkillNode::AREA_CUSTOM));
        }
    }
    
    UtilityFunctions::print("Tree parsed successfully. Total nodes: ", parsed_nodes.size());
    return parsed_nodes;
}


    void SkillManager::add_obligation(SkillNode* node) {
        if (!node) return;
        
        Dictionary task;
        task["id"] = node->getSkillId();
        task["name"] = node->getSkillName();
        task["level"] = node->getSkillLevel();
        task["cd_type"] = node->getCooldownType();  
        task["task_type"] = node->getTaskType();   
        task["target"] = node->getSkillNesProg();  
        task["current"] = node->getSkillCurProg();  

        for (int i = 0; i < active_obligations.size(); i++) {
            Dictionary existing = active_obligations[i];
            if (existing["id"] == task["id"]) {
                active_obligations[i] = task; 
                
                emit_signal("obligations_updated"); 
                return;
            }
        }
        active_obligations.append(task);
        emit_signal("obligations_updated");
    }


    Dictionary SkillManager::get_skill_data(const String& id) {
        if (skill_catalog.has(id)) {
            return skill_catalog[id];
        }
        return Dictionary();
    }


    void SkillManager::log_action(const String& skill_id, int progress_added) {
    Dictionary log_entry;
    log_entry["skill_id"] = skill_id;
    log_entry["progress_added"] = progress_added;
    
    int64_t ts = godot::Time::get_singleton()->get_unix_time_from_system();
    log_entry["timestamp"] = ts;
    
    Dictionary time_dict = godot::Time::get_singleton()->get_datetime_dict_from_unix_time(ts);
    String date_str = String::num_int64((int)time_dict["year"]) + "-" + 
                      String::num_int64((int)time_dict["month"]) + "-" + 
                      String::num_int64((int)time_dict["day"]);
                      
    log_entry["date"] = date_str;
    
    action_history.append(log_entry);
    UtilityFunctions::print("Action logged | Date: ", date_str);
}


int SkillManager::calculate_current_streak() const {
    if (action_history.size() == 0) return 0;

    std::vector<int64_t> days;
    for (int i = 0; i < action_history.size(); i++) {
        Dictionary act = action_history[i];
        if (act.has("timestamp")) {
            int64_t ts = act["timestamp"];
            int64_t day = ts / 86400;
            
            if (std::find(days.begin(), days.end(), day) == days.end()) {
                days.push_back(day);
            }
        }
    }

    if (days.empty()) return 0;

    std::sort(days.begin(), days.end(), std::greater<int64_t>());

    int64_t current_day = Time::get_singleton()->get_unix_time_from_system() / 86400;
    int streak = 0;
    int64_t check_day = current_day;

    if (days[0] == current_day) {
    } else if (days[0] == current_day - 1) {
        check_day = current_day - 1;
    } else {
        return 0;
    }

    for (size_t i = 0; i < days.size(); i++) {
        if (days[i] == check_day) {
            streak++;
            check_day--; 
        } else {
            break;
        }
    }
    return streak;
}