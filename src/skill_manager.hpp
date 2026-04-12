#ifndef SKILL_MANAGER_H
#define SKILL_MANAGER_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/classes/json.hpp> 

#include "skill_node.hpp"

namespace godot{

class SkillManager : public Node {
    GDCLASS(SkillManager, Node)

private:
    Dictionary skill_catalog;               //полный список навыков
    bool is_on_cooldown;                    //крч если юзер вкачал навык и у
                                            //него утренние прокачки закончили (штуки 3-4)
                                            //то он после прокачки навыка не может качать следуюзтй в течении 30 мин
    
    float cooldown_timer_sec;               //оставшееся время отдыха
    const float COOLDOWN_TIME = 1800.0f;    //дефолт время отдыха
    const int MAX_DAILY_STARTS = 3;         //сколько навыков можно вкачать в день сразу без делея
    int instant_starts_left;                //скок осталось вкачать

protected:
    static void _bind_methods();
    
public:
    SkillManager();
    ~SkillManager();

    void _process(double delta) override;                   //тик каждый кадр
    
    void load_catalog_from_json(const String& json_string); //загрузка каталога

    int roll_rarity();                                      //возращает редкость
    String roll_new_skill(int parent_area);                 //выдача случайного навыка по редкости

    bool can_start_new_skill() const;                       //ну аналогично названию
    bool request_start_skill();                             //после завершения прокачки навыка
    float get_cooldown_time_left() const;                   //время до конца отдыха 
    void reset_daily_starts();                              //утром сброс бонусов
    Array parse_user_tree(const String& json_string);       //парсим json возращаем array из skillnode* 
};


}//namespace годотика




#endif //SKILL_MANAGER_H