#ifndef SKILL_TREE_H
#define SKILL_TREE_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <map>
#include <vector>

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
    
    void clear_nodes();
    
    void place_node_on_map(SkillNode* new_node, SkillNode* parent_node, int child_index);
private:
    Dictionary node_map;                            // id->skillnode*

    std::map<int, std::map<int, std::vector<SkillNode*>>> nodes_by_area_and_depth;
    
    float node_size = 110.0f;    
    float base_radius = 160.0f; 

    int compute_depth(SkillNode* node);
    Vector2 get_sector_root(SkillNode* node);
    float get_base_angle(int area);
    void relayout_layer(int depth, int area, const Vector2& root_pos);
};

}

#endif