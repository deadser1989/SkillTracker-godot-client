#include "skill_node.hpp"

#include <godot_cpp/classes/property_tweener.hpp>
#include <godot_cpp/classes/interval_tweener.hpp>
#include <godot_cpp/classes/callback_tweener.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp> //для принтов в консоль годота

using namespace godot;

void SkillNode::_bind_methods() { 
    //регистрация метродов для редактора(годотика)
ClassDB::bind_method(D_METHOD("set_skill_id", "id"), &SkillNode::setSkillId);
    ClassDB::bind_method(D_METHOD("get_skill_id"), &SkillNode::getSkillId);
    
    ClassDB::bind_method(D_METHOD("set_skill_state", "state"), &SkillNode::setSkillState);
    ClassDB::bind_method(D_METHOD("get_skill_state"), &SkillNode::getState);

    ClassDB::bind_method(D_METHOD("set_skill_rarity", "rarity"), &SkillNode::setSkillRarity);
    ClassDB::bind_method(D_METHOD("get_skill_rarity"), &SkillNode::getRarity);

    ClassDB::bind_method(D_METHOD("set_skill_subject_area", "subj"), &SkillNode::setSkillSubjectArea);
    ClassDB::bind_method(D_METHOD("get_subject_area"), &SkillNode::getSubjectArea);

    ClassDB::bind_method(D_METHOD("set_skill_xp", "xp"), &SkillNode::setSkillXP);
    ClassDB::bind_method(D_METHOD("get_skill_xp"), &SkillNode::getSkillXP);

    ClassDB::bind_method(D_METHOD("set_skill_cur_prog", "prog"), &SkillNode::setSkillCurProg);
    ClassDB::bind_method(D_METHOD("get_skill_cur_prog"), &SkillNode::getSkillCurProg);

    ClassDB::bind_method(D_METHOD("set_skill_nes_prog", "prog"), &SkillNode::setSkillNesProg);
    ClassDB::bind_method(D_METHOD("get_skill_nes_prog"), &SkillNode::getSkillNesProg);
    
    ClassDB::bind_method(D_METHOD("set_skill_time", "time"), &SkillNode::setSkillTime);
    ClassDB::bind_method(D_METHOD("get_skill_time"), &SkillNode::getSkillTime);

    ClassDB::bind_method(D_METHOD("set_required_prev_skills", "skills"), &SkillNode::setRequiredPrevSkills);
    ClassDB::bind_method(D_METHOD("get_required_prev_skills"), &SkillNode::getRequiredPrevSkills);

    ClassDB::bind_method(D_METHOD("add_progress", "prog"), &SkillNode::addProgress);
    ClassDB::bind_method(D_METHOD("start_progress_time"), &SkillNode::startProgressTime);

    ClassDB::bind_method(D_METHOD("set_tex_border", "tex"), &SkillNode::setTexBorder);
    ClassDB::bind_method(D_METHOD("get_tex_border"), &SkillNode::getTexBorder);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "tex_border", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"), "set_tex_border", "get_tex_border");

    ClassDB::bind_method(D_METHOD("set_icon_read_on", "tex"), &SkillNode::setIconReadOn);
    ClassDB::bind_method(D_METHOD("get_icon_read_on"), &SkillNode::getIconReadOn);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "icon_read_on", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"), "set_icon_read_on", "get_icon_read_on");

    ClassDB::bind_method(D_METHOD("set_icon_read_off", "tex"), &SkillNode::setIconReadOff);
    ClassDB::bind_method(D_METHOD("get_icon_read_off"), &SkillNode::getIconReadOff);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "icon_read_off", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"), "set_icon_read_off", "get_icon_read_off");

    ClassDB::bind_method(D_METHOD("set_icon_fit_on", "tex"), &SkillNode::setIconFitOn);
    ClassDB::bind_method(D_METHOD("get_icon_fit_on"), &SkillNode::getIconFitOn);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "icon_fit_on", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"), "set_icon_fit_on", "get_icon_fit_on");

    ClassDB::bind_method(D_METHOD("set_icon_fit_off", "tex"), &SkillNode::setIconFitOff);
    ClassDB::bind_method(D_METHOD("get_icon_fit_off"), &SkillNode::getIconFitOff);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "icon_fit_off", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"), "set_icon_fit_off", "get_icon_fit_off");

    ClassDB::bind_method(D_METHOD("set_icon_language_on", "tex"), &SkillNode::setIconLanguageOn);
    ClassDB::bind_method(D_METHOD("get_icon_language_on"), &SkillNode::getIconLanguageOn);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "icon_language_on", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"), "set_icon_language_on", "get_icon_language_on");

    ClassDB::bind_method(D_METHOD("set_icon_language_off", "tex"), &SkillNode::setIconLanguageOff);
    ClassDB::bind_method(D_METHOD("get_icon_language_off"), &SkillNode::getIconLanguageOff);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "icon_language_off", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"), "set_icon_language_off", "get_icon_language_off");

    ClassDB::bind_method(D_METHOD("set_icon_creativity_on", "tex"), &SkillNode::setIconCreativityOn);
    ClassDB::bind_method(D_METHOD("get_icon_creativity_on"), &SkillNode::getIconCreativityOn);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "icon_creativity_on", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"), "set_icon_creativity_on", "get_icon_creativity_on");

    ClassDB::bind_method(D_METHOD("set_icon_creativity_off", "tex"), &SkillNode::setIconCreativityOff);
    ClassDB::bind_method(D_METHOD("get_icon_creativity_off"), &SkillNode::getIconCreativityOff);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "icon_creativity_off", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"), "set_icon_creativity_off", "get_icon_creativity_off");

    ClassDB::bind_method(D_METHOD("set_icon_custom_on", "tex"), &SkillNode::setIconCustomOn);
    ClassDB::bind_method(D_METHOD("get_icon_custom_on"), &SkillNode::getIconCustomOn);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "icon_custom_on", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"), "set_icon_custom_on", "get_icon_custom_on");

    ClassDB::bind_method(D_METHOD("set_icon_custom_off", "tex"), &SkillNode::setIconCustomOff);
    ClassDB::bind_method(D_METHOD("get_icon_custom_off"), &SkillNode::getIconCustomOff);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "icon_custom_off", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"), "set_icon_custom_off", "get_icon_custom_off");

    ClassDB::bind_method(D_METHOD("set_skill_level", "lvl"), &SkillNode::setSkillLevel);
    ClassDB::bind_method(D_METHOD("get_skill_level"), &SkillNode::getSkillLevel);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "current_level"), "set_skill_level", "get_skill_level");
    
    //бинд свойств чтобы появились в редакторе
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "skill_id"), "set_skill_id", "get_skill_id");

    //бинд enum чтобы появлялись как выпадающие списки
    ADD_PROPERTY(PropertyInfo( //состояния
        Variant::INT,
        "current_state",
        PROPERTY_HINT_ENUM,
        "Hidden,Revealed,Active,Finished"),
        "set_skill_state",
        "get_skill_state"
    );

    ADD_PROPERTY(PropertyInfo(
        Variant::INT,
        "current_rare",
        PROPERTY_HINT_ENUM,
        "Common,Rare,Epic,Legendary"),
        "set_skill_rarity",
        "get_skill_rarity"
    );

    ADD_PROPERTY(PropertyInfo(
        Variant::INT,
        "current_subject",
        PROPERTY_HINT_ENUM,
        "Reading,Fitness,Language,Creativity,Custom"),
        "set_skill_subject_area",
        "get_subject_area"
    );

    //свойства опыта, времени прогресса
    ADD_PROPERTY(PropertyInfo(Variant::INT, "received_xp"), "set_skill_xp", "get_skill_xp");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "time_for_upgrade_sec"), "set_skill_time", "get_skill_time");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "current_progress"), "set_skill_cur_prog", "get_skill_cur_prog");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "necessary_progress"), "set_skill_nes_prog", "get_skill_nes_prog");

    //массив предыдущих навыков
    ADD_PROPERTY(PropertyInfo(
        Variant::PACKED_STRING_ARRAY,
        "required_prev_skills"),
        "set_required_prev_skills", 
        "get_required_prev_skills"
    );

    //сигналы для интерфейса
    ADD_SIGNAL(MethodInfo("progress_updated", PropertyInfo(Variant::INT, "current"), PropertyInfo(Variant::INT, "necessary")));
    ADD_SIGNAL(MethodInfo("skill_finished"));
}


//конструктор
SkillNode::SkillNode() {
    set_process(true); 
    border_sprite = nullptr;
    icon_sprite = nullptr;
    current_level = 1;

    skill_id = "new_skill"; //задаем начальные значения
    skill_name = "New Skill";
    skill_title = "Description";
    
    current_state = STATE_HIDDEN;
    current_rare = RARITY_COMMON;
    current_subject = AREA_CUSTOM;

    received_xp = 10;
    current_progress = 0;
    necessary_progress = 100;

    time_for_upgrade = -1;  //автоматом будет стоять чтобы безвременные навыки не показывались
    is_timer_running = false;
    current_timer_sec = 0.0f;
    
}


SkillNode::~SkillNode() {
}


// гетеры/сеттеры...
void SkillNode::setSkillLevel(int level) { current_level = level; }
int SkillNode::getSkillLevel() const { return current_level; }

void SkillNode::setSkillId(const String& id) { skill_id = id; }
String SkillNode::getSkillId() const { return skill_id; }

void SkillNode::setSkillName(const String& name) { skill_name = name; }
String SkillNode::getSkillName() const { return skill_name; }

void SkillNode::setSkillTitle(const String& title) { skill_title = title; }
String SkillNode::getSkillTitle() const { return skill_title; }

void SkillNode::setSkillState(int state) { current_state = (SkillState)state; updateVisuals(true); }
int SkillNode::getState() const { return (int)current_state; }

void SkillNode::setSkillRarity(int rarity) { current_rare = (SkillRarity)rarity; }
int SkillNode::getRarity() const { return (int)current_rare; }

void SkillNode::setSkillSubjectArea(int sub) { current_subject = (SkillSubjectArea)sub;  updateVisuals(false); }
int SkillNode::getSubjectArea() const { return (int)current_subject; }

void SkillNode::setSkillXP(int xp) { received_xp = xp; }
int SkillNode::getSkillXP() const { return received_xp; }

void SkillNode::setSkillTime(int time) { time_for_upgrade = time; }
int SkillNode::getSkillTime() const { return time_for_upgrade; }

void SkillNode::setSkillCurProg(int c_prog) { current_progress = c_prog; }
int SkillNode::getSkillCurProg() const { return current_progress; }

void SkillNode::setSkillNesProg(int n_prog) { necessary_progress = n_prog; }
int SkillNode::getSkillNesProg() const { return necessary_progress; }

void SkillNode::setRequiredPrevSkills(const PackedStringArray& skills) { required_prev_skills = skills; }
PackedStringArray SkillNode::getRequiredPrevSkills() const { return required_prev_skills; }


///____________игровая логика_______________

void SkillNode::addProgress(int prog) {     //добавляем прогресс
    if (current_state != STATE_ACTIVE) {    //искл
        UtilityFunctions::print("CANNOT ADD PROGRESS! SKILL IS NOT ACTIVE!");
        return;
    }

    current_progress += prog;

    if (current_progress >= necessary_progress) {   //достигли необходимого прогресса чтобы завершить?
        current_progress = necessary_progress;
        current_state = STATE_FINISHED;             //меняем состояние на завершенный навык

        emit_signal("progress_updated", current_progress, necessary_progress);
        emit_signal("skill_finished");
        UtilityFunctions::print("Skill ", skill_name, " Finished!!!");
    } else {
        emit_signal("progress_updated", current_progress, necessary_progress);
    }
}

void SkillNode::startProgressTime() {
    if (time_for_upgrade > 0 && current_state == STATE_ACTIVE) {
        is_timer_running = true;
        current_timer_sec = (float)time_for_upgrade;
        UtilityFunctions::print("Timer started for: ", skill_name);
    }
}


//___обновление кадров 
void SkillNode::_process(double delta) {
    //если таймер запущен то отнимаем время
    if (is_timer_running) {
        current_timer_sec -= delta; //delta - доли снкнд между кадрами
        
        if (current_timer_sec <= 0.0f) {
            current_timer_sec = 0.0f;
            is_timer_running = false;
            
            UtilityFunctions::print("Timer finished for: ", skill_name);
            
            //добавить вопрос о выполнелил пользователь задание? если нет, то можно будет приступить позже
            // current_progress = necessary_progress; 
            // addProgress(0); //завершаем навык
        }
    }
}


void SkillNode::_notification(int p_what) {
    if (p_what == NOTIFICATION_READY) {
        if (!border_sprite) {
            border_sprite = memnew(Sprite2D);
            add_child(border_sprite);
        }
        if (!icon_sprite) {
            icon_sprite = memnew(Sprite2D);
            add_child(icon_sprite);
        }
        updateVisuals(false);
    }
}

void SkillNode::updateVisuals(bool animate){
    if (!icon_sprite || !border_sprite) {
        return;
    }

    bool is_active = (current_state == STATE_ACTIVE || current_state == STATE_FINISHED);
    Ref<Texture2D> current_tex;

    switch (current_subject) {
        case AREA_READING: current_tex = is_active ? icon_read_on : icon_read_off; break;
        case AREA_FITNESS: current_tex = is_active ? icon_fit_on  : icon_fit_off; break;
        case AREA_LANGUAGE: current_tex = is_active ? icon_language_on : icon_language_off; break;
        case AREA_CREATIVITY: current_tex = is_active ? icon_creativity_on : icon_creativity_off; break;
        default: current_tex = is_active ? icon_custom_on : icon_custom_off; break;
    }

    icon_sprite->set_texture(current_tex);
    border_sprite->set_texture(tex_border);

    Color target_color = Color(1, 1, 1, 1);
    float target_scale = 1.0f;
    
    switch (current_state) {
        case STATE_HIDDEN: set_visible(false);
            break;
        case STATE_REVEALED:
            set_visible(true);
            target_color = Color(0.3, 0.3, 0.3, 0.6);   //темни принц(оттенок)
            target_scale = 0.9f;
            break;
        case STATE_ACTIVE:
            set_visible(true);
            target_color = Color(1, 1, 1, 1); 
            target_scale = 1.05f;
            break;
        case STATE_FINISHED:
            set_visible(true);
            target_color = Color(1, 0.9, 0.4, 1);     //золотой
            target_scale = 1.1f;
            break;
    }   

    if (animate && is_inside_tree()) {
        Ref<Tween> tween = get_tree()->create_tween();
        tween->set_parallel(true);
        tween->tween_property(this, "modulate", target_color, 0.4);
        tween->tween_property(this, "scale", Vector2(target_scale, target_scale), 0.4);
    } else {
        set_modulate(target_color);
        set_scale(Vector2(target_scale, target_scale));
    }

    Color border_color = Color(1, 1, 1, 1);      //бели

    switch (current_rare) {
        case RARITY_COMMON: 
            border_color = Color(0.6, 0.4, 0.2); //коричневи
            break;
        case RARITY_RARE: 
            border_color = Color(0.2, 0.5, 0.9); //сини
            break;
        case RARITY_EPIC: 
            border_color = Color(0.7, 0.2, 0.8); //фиол
            break;
        case RARITY_LEGENDARY: 
            border_color = Color(1.0, 0.8, 0.1); //голд
            break;
    }

    border_sprite->set_modulate(border_color);
}