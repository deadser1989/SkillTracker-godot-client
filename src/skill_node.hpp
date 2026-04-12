#ifndef SKILL_NODE_H
#define SKILL_NODE_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/sprite2d.hpp>
#include <godot_cpp/classes/tween.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/classes/texture2d.hpp>

namespace godot {

class SkillNode : public Node2D {
    GDCLASS(SkillNode, Node2D)

public:                         //STATES
    enum SkillState {
        STATE_HIDDEN = 0,       //не видно
        STATE_REVEALED = 1,     //видно, залочено
        STATE_ACTIVE = 2,       //разблочено, активно
        STATE_FINISHED =3       //закончен (для временных)
    };

    enum SkillRarity {          //редкости навыка
        RARITY_COMMON = 0,
        RARITY_RARE =1 ,
        RARITY_EPIC = 2,
        RARITY_LEGENDARY = 3
    };

    enum SkillSubjectArea {     //тип (область/направление) прокачки
        AREA_READING = 0,
        AREA_FITNESS = 1,
        AREA_LANGUAGE = 2,
        AREA_CREATIVITY = 3,    //?? мб потом область поменять нужно на что то более значимое
        AREA_CUSTOM = 4,
    };

private:
    //узлы(рамки)
    Sprite2D* border_sprite;
    Sprite2D* icon_sprite;

    //текстуры
    Ref<Texture2D> tex_border;          //кружок для навыков
    Ref<Texture2D> icon_read_on;        //книга/вкл
    Ref<Texture2D> icon_read_off;       //     /выкл(НЕ ПРОКАЧЕНО, все что ниже аналогично)

    Ref<Texture2D> icon_fit_on;         //фитнесс
    Ref<Texture2D> icon_fit_off;

    Ref<Texture2D> icon_language_on;    //язык
    Ref<Texture2D> icon_language_off; 

    Ref<Texture2D> icon_creativity_on;  //креативность
    Ref<Texture2D> icon_creativity_off;

    Ref<Texture2D> icon_custom_on;      //кастомная
    Ref<Texture2D> icon_custom_off;

    void updateVisuals(bool animate = true);             //для переключения визуала

private:
    String skill_id;                    //идентификатор
    String skill_name;                  //имя
    String skill_title;                 //описание навыка

    SkillState current_state;           //текущее состояние
    SkillRarity current_rare;           //редкость
    SkillSubjectArea current_subject;   //направление прокачки

    int received_xp;                    //сколько xp получит
    int current_progress;               //насколько выполнен навык в данный момент
    int necessary_progress;             //сколько нужно выполнить
    int current_level;
    
    String icon_path;                   //путь к картинкек

    int time_for_upgrade;               //время прокачки (не для продолжительных навыков можно сделатт =-1)
    bool is_timer_running;              //начался ли таймер с момента начала прокачки навыка (в пример 5 дней читать по 15 страниц, либо просто таймер начни читать 30 мин книгу)
    float current_timer_sec;            //текущее время таймера
    
    PackedStringArray required_prev_skills; //оптимизированный массив id предыдущих node-ов

protected:
    static void _bind_methods();        //тут биндим методы и свойства
    void _notification(int mes);        //инициализация спрайта

public:
    SkillNode();
    ~SkillNode();

    //сеттеры / гетеры
    void setSkillId(const String& id);
    String getSkillId() const;
    void setSkillName(const String& name);
    String getSkillName() const;
    void setSkillTitle(const String& title);
    String getSkillTitle() const;
    void setSkillState(int state);
    int getState() const;
    void setSkillRarity(int rarity);
    int getRarity() const;
    void setSkillSubjectArea(int subj);
    int getSubjectArea() const;
    void setSkillXP(int xp);
    int getSkillXP() const;
    void setSkillTime(int time);
    int getSkillTime() const;
    void setSkillCurProg(int c_prog);
    int getSkillCurProg() const; 
    void setSkillNesProg(int n_prog);
    int getSkillNesProg() const;
    void setSkillLevel(int level);
    int getSkillLevel() const;
    void setRequiredPrevSkills(const PackedStringArray& skills);
    PackedStringArray getRequiredPrevSkills() const;
    

    void setTexBorder(const Ref<Texture2D> p_tex) { tex_border = p_tex; updateVisuals(false); }
    Ref<Texture2D> getTexBorder() const { return tex_border; }

    void setIconReadOn(const Ref<Texture2D> p_tex) { icon_read_on = p_tex; updateVisuals(false); }
    Ref<Texture2D> getIconReadOn() const { return icon_read_on; }
    void setIconReadOff(const Ref<Texture2D> p_tex) { icon_read_off = p_tex; updateVisuals(false); }
    Ref<Texture2D> getIconReadOff() const { return icon_read_off; }

    void setIconFitOn(const Ref<Texture2D> p_tex) { icon_fit_on = p_tex; updateVisuals(false); }
    Ref<Texture2D> getIconFitOn() const { return icon_fit_on; }
    void setIconFitOff(const Ref<Texture2D> p_tex) { icon_fit_off = p_tex; updateVisuals(false); }
    Ref<Texture2D> getIconFitOff() const { return icon_fit_off; }

    void setIconLanguageOn(const Ref<Texture2D> p_tex) { icon_language_on = p_tex; updateVisuals(false); }
    Ref<Texture2D> getIconLanguageOn() const { return icon_language_on; }
    void setIconLanguageOff(const Ref<Texture2D> p_tex) { icon_language_off = p_tex; updateVisuals(false); }
    Ref<Texture2D> getIconLanguageOff() const { return icon_language_off; }

    void setIconCreativityOn(const Ref<Texture2D> p_tex) { icon_creativity_on = p_tex; updateVisuals(false); }
    Ref<Texture2D> getIconCreativityOn() const { return icon_creativity_on; }
    void setIconCreativityOff(const Ref<Texture2D> p_tex) { icon_creativity_off = p_tex; updateVisuals(false); }
    Ref<Texture2D> getIconCreativityOff() const { return icon_creativity_off;}

    void setIconCustomOn(const Ref<Texture2D> p_tex) { icon_custom_on = p_tex; updateVisuals(false); }
    Ref<Texture2D> getIconCustomOn() const { return icon_custom_on; }
    void setIconCustomOff(const Ref<Texture2D> p_tex) { icon_custom_off = p_tex; updateVisuals(false); }
    Ref<Texture2D> getIconCustomOff() const { return icon_custom_off; }

    void addProgress(int prog); //добавить выполнение задачи
    void startProgressTime();   //старт таймера
    void _process(double delta) override; //кадры для таймера
};

}

//чтобы godot понимал enum
VARIANT_ENUM_CAST(godot::SkillNode::SkillState);
VARIANT_ENUM_CAST(godot::SkillNode::SkillRarity);
VARIANT_ENUM_CAST(godot::SkillNode::SkillSubjectArea);

#endif //SKILL_NODE_H