#include "skill_manager.hpp"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void SkillManager::_bind_methods() {
    ClassDB::bind_method(D_METHOD("load_catalog_from_json", "json"), &SkillManager::load_catalog_from_json);
    ClassDB::bind_method(D_METHOD("roll_rarity"), &SkillManager::roll_rarity);
    ClassDB::bind_method(D_METHOD("roll_new_skill", "parent_area"), &SkillManager::roll_new_skill);
    ClassDB::bind_method(D_METHOD("can_start_new_skill"), &SkillManager::can_start_new_skill);
    ClassDB::bind_method(D_METHOD("request_start_skill"), &SkillManager::request_start_skill);
    ClassDB::bind_method(D_METHOD("get_cooldown_time_left"), &SkillManager::get_cooldown_time_left);
    ClassDB::bind_method(D_METHOD("reset_daily_starts"), &SkillManager::reset_daily_starts);
    ClassDB::bind_method(D_METHOD("parse_user_tree", "json_string"), &SkillManager::parse_user_tree);

    ADD_SIGNAL(MethodInfo("cooldown_started"));
    ADD_SIGNAL(MethodInfo("cooldown_finished"));    //чтобы ui знал что времяч прошло
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
        UtilityFunctions::print("CATALOG PARSE ERROR: ", json->get_error_message());
        return;
    }

    skill_catalog.clear();
    Array skills_array = json->get_data();
    
    for (int i = 0; i < skills_array.size(); i++) {
        Dictionary dict = skills_array[i];
   
        String id_str = String::num_int64((int)dict["id"]);

        skill_catalog[id_str] = dict;
    }

    UtilityFunctions::print("Catalog loaded!");
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


String SkillManager::roll_new_skill(int parent_area) {
    int target_rarity = roll_rarity();
    UtilityFunctions::print("Rolled rarity: ", target_rarity, " | For Area: ", parent_area);
    
    PackedStringArray valid_skills;                                  //подходящие варианты
    Array keys = skill_catalog.keys();                               //все ID в каталоге

    // Пробегаемся по всему каталогу
    for (int i = 0; i < keys.size(); i++) {
        String key = keys[i];
        Dictionary skill_data = skill_catalog[key];

        int s_rarity = (int)skill_data["node_rarity"]; 
        int s_area = (int)skill_data["area"];
        
        if (s_rarity == target_rarity && s_area == parent_area) {   //совпали редкость и область у юзера 
            //дописать проверку есть ли у юзера такой скилл уже
            valid_skills.append(key);                               //добавляем в корзину
        }
    }

    if (valid_skills.size() == 0) {                                 //от ошибоук
        UtilityFunctions::print("WARNING: No skills found for this area");
        return keys.size() > 0 ? (String)keys[0] : "error";
    }

    int random_index = UtilityFunctions::randi() % valid_skills.size();
    
    String won_skill_id = valid_skills[random_index];
    UtilityFunctions::print(" New skill ID!!!: ", won_skill_id);
    
    return won_skill_id;
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
        UtilityFunctions::print("Cannot start! User is on 30 min cooldown.");
        return false;
    }
    return true;
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
        return parsed_nodes;
    }
    
    Array nodes_array = json->get_data();

    for (int i = 0; i < nodes_array.size(); i++) {
        Dictionary dict = nodes_array[i];
        SkillNode* new_node = memnew(SkillNode);
        
        new_node->setSkillId(String::num_int64((int)dict["id"]));
        new_node->setSkillName(dict["node_name"]);
        new_node->setSkillTitle(dict["node_info"]);
        
        new_node->setSkillLevel((int)dict["node_level"]);
        new_node->setSkillRarity((int)dict.get("node_rarity", SkillNode::RARITY_COMMON));
        new_node->setSkillXP((int)dict["xp_reward"]);
        new_node->setSkillCurProg((int)dict["current_progress"]);
        new_node->setSkillNesProg((int)dict["target_progress"]);

        String s_state = dict["node_state"];
        if (s_state == "hidden") new_node->setSkillState(SkillNode::STATE_HIDDEN);
        else if (s_state == "revealed") new_node->setSkillState(SkillNode::STATE_REVEALED);
        else if (s_state == "active") new_node->setSkillState(SkillNode::STATE_ACTIVE);
        else new_node->setSkillState(SkillNode::STATE_FINISHED);

        Variant parent_val = dict["parent"];        //парсим предка если есть
        if (parent_val.get_type() != Variant::NIL) {
            PackedStringArray reqs;
            reqs.append(String::num_int64((int)parent_val));
            new_node->setRequiredPrevSkills(reqs);
        }

        parsed_nodes.append(new_node);
    }
    
    UtilityFunctions::print("User tree parsed! Nodes count: ", parsed_nodes.size());
    return parsed_nodes;
}