#ifndef SKILL_TREE_H
#define SKILL_TREE_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/file_access.hpp>

#include "skill_node.hpp"

namespace godot {

class SkillTree : public Node2D {
    GDCLASS(SkillTree, Node2D)

protected:
    static void _bind_methods();

public:
    SkillTree();
    ~SkillTree();

    void _draw() override;                          //рисование связей

    void _process(double delta) override;           //обновление в редакторе

    SkillNode* find_skill_node(const String& p_id); //поиск узла по id
  
    void reveal_successors(SkillNode* p_node);      //раскрытие соседних навыков при завешении

    void registerNode(SkillNode* node);
    
private:
    Dictionary node_map;                            // id->skillnode*
};

}

#endif