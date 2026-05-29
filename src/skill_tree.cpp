#include "skill_tree.hpp"
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void SkillTree::_bind_methods() {
    ClassDB::bind_method(D_METHOD("reveal_successors", "skill_node"), &SkillTree::reveal_successors);
    ClassDB::bind_method(D_METHOD("registerNode", "node"), &SkillTree::registerNode);
    ClassDB::bind_method(D_METHOD("clear_nodes"), &SkillTree::clear_nodes); 
    ClassDB::bind_method(D_METHOD("find_skill_node", "id"), &SkillTree::find_skill_node);
    ClassDB::bind_method(D_METHOD("place_node_on_map", "new_node", "parent_node", "child_index"), &SkillTree::place_node_on_map);
}

SkillTree::SkillTree() { 
    set_z_index(-1);
}

SkillTree::~SkillTree() {}

void SkillTree::clear_nodes() {
    node_map.clear();
    nodes_by_area_and_depth.clear(); 
}

SkillNode* SkillTree::find_skill_node(const String& id) {
    if (!node_map.has(id)) return nullptr;
    return Object::cast_to<SkillNode>(node_map[id]);
}

void SkillTree::_draw() {
    for (int i = 0; i < get_child_count(); i++) {
        SkillNode* current = Object::cast_to<SkillNode>(get_child(i));
        if (!current || current->getState() == SkillNode::STATE_HIDDEN) continue;

        PackedStringArray parents = current->getRequiredPrevSkills();
        for (int j = 0; j < parents.size(); j++) {
            SkillNode* parent_node = find_skill_node(parents[j]);
            
            if (parent_node && parent_node->getState() != SkillNode::STATE_HIDDEN) { 
                
                PackedVector2Array points;
                points.append(parent_node->get_position());
                points.append(current->get_position());

                Color c_parent = parent_node->getRarityColor();
                Color c_child = current->getRarityColor();
                
                PackedColorArray inner_colors;
                inner_colors.append(c_parent);
                inner_colors.append(c_child);

                PackedColorArray outline_colors;
                outline_colors.append(c_parent.darkened(0.7f));
                outline_colors.append(c_child.darkened(0.7f));

                float outline_width = 20.0f; 
                float inner_width = 12.0f;  

                draw_polyline_colors(points, outline_colors, outline_width, true);
                draw_polyline_colors(points, inner_colors, inner_width, true);
            }
        }
    }
}

void SkillTree::reveal_successors(SkillNode* p_node) {
    if (!p_node) return;
    String id = p_node->getSkillId();
    
    Array keys = node_map.keys();

    for (int i = 0; i < keys.size(); i++) {
        SkillNode* target = Object::cast_to<SkillNode>(node_map[keys[i]]);
        if (!target || target->getState() != SkillNode::STATE_HIDDEN) continue;

        PackedStringArray reqs = target->getRequiredPrevSkills();
        bool all_done = true;

        for (int k = 0; k < reqs.size(); k++) {
            SkillNode* parent = find_skill_node(reqs[k]);
            if (!parent || parent->getState() < SkillNode::STATE_ACTIVE) {
                all_done = false;
                break;
            }
        }

        if (all_done) {
            target->setSkillState(SkillNode::STATE_REVEALED);
        }
    }
    queue_redraw(); //перирисовка линий
}

void SkillTree::_process(double delta) {
    if (Engine::get_singleton()->is_editor_hint()) {
        queue_redraw();
    }
}

void SkillTree::registerNode(SkillNode* node) {
    String id = node->getSkillId();

    node_map[id] = node;
}

void SkillTree::place_node_on_map(SkillNode* new_node, SkillNode* parent_node, int child_index) {
    if (!parent_node) {
        new_node->set_tree_depth(0);
        new_node->set_layer_index(0);
        return; 
    }

    int depth = parent_node->get_tree_depth() + 1;                      //индексируем ноды родителей и детей
    int index = (parent_node->get_layer_index() * 2) + child_index;

    new_node->set_tree_depth(depth);
    new_node->set_layer_index(index);

    Vector2 root_pos = Vector2(0, 0);
    SkillNode* current = parent_node;
    while (current && current->get_tree_depth() > 0) {
        if (current->getRequiredPrevSkills().size() > 0) {
            current = find_skill_node(current->getRequiredPrevSkills()[0]);
        } else {
            break;
        }
    }
    if (current) root_pos = current->get_position();

    int area = new_node->getSubjectArea();                              //ось сектора
    float base_angle = 0.0f;
    if (area == SkillNode::AREA_READING)      base_angle = -Math_PI / 2.0f; //вверх
    else if (area == SkillNode::AREA_FITNESS) base_angle = 0.0f;            //вправо
    else if (area == SkillNode::AREA_LANGUAGE)base_angle = Math_PI / 2.0f;  //вниз
    else                                      base_angle = Math_PI;         //влево

    float max_spread = Math_PI / 4.0f;          //45 градусов
    float start_angle = base_angle - max_spread;
    float end_angle = base_angle + max_spread;

    int nodes_in_layer = 1 << depth;            //2 в степени тепени depth - 2,4 и тд узлов
    float t = (float)index / (float)(nodes_in_layer - 1); 
    float final_angle = start_angle + (t * (end_angle - start_angle));

    // расстояние между нодами чтобы вместиьься уджваивается постоянно 
    float base_distance = 70.0f; 
    float radius = base_distance * ((1 << depth) - 1)+50.0; 

    //x = cos(a) * R, y = sin(a) * R
    Vector2 final_pos = root_pos + Vector2(Math::cos(final_angle) * radius, Math::sin(final_angle) * radius);

    new_node->set_position(final_pos);

    if (!new_node->is_inside_tree()) {
        add_child(new_node);
    }
    queue_redraw();
}

int SkillTree::compute_depth(SkillNode* node) {
    int depth = 1;
    SkillNode* current = node;
    while (current && current->getRequiredPrevSkills().size() > 0) {
        depth++;
        String parent_id = current->getRequiredPrevSkills()[0];
        current = find_skill_node(parent_id);
    }
    return depth;
}

Vector2 SkillTree::get_sector_root(SkillNode* node) {
    SkillNode* current = node;
    while (current && current->getRequiredPrevSkills().size() > 0) {
        String parent_id = current->getRequiredPrevSkills()[0];
        current = find_skill_node(parent_id);
    }
    if (current) return current->get_position();
    return Vector2(0, 0);
}

float SkillTree::get_base_angle(int area) {
    if (area == SkillNode::AREA_READING)       return -Math_PI / 2.0f; //вверх (-90 град)
    if (area == SkillNode::AREA_FITNESS)       return 0.0f;            //вправо (0 град)
    if (area == SkillNode::AREA_LANGUAGE)      return Math_PI / 2.0f;  //вниз (90 град)
    return Math_PI;
}

void SkillTree::relayout_layer(int depth, int area, const Vector2& root_pos) {
    std::vector<SkillNode*>& layer = nodes_by_area_and_depth[area][depth];
    int count = layer.size();
    if (count == 0) return;

    float base_angle = get_base_angle(area);
    
    float sector_arc = Math_PI / 2.2f; 
    float start_angle = base_angle - (sector_arc / 2.0f);
    
    float radius = depth * 140.0f;
    float node_size = 90.0f; 
    
    float required_arc_length = count * node_size;
    float current_arc_length = radius * sector_arc;
    
    if (current_arc_length < required_arc_length) {
        radius = required_arc_length / sector_arc;
    }

    for (int i = 0; i < count; i++) {
        float t = 0.5f; 
        if (count > 1) {
            t = (float)i / (float)(count - 1); 
        }
        
        float final_angle = start_angle + (t * sector_arc);
        
        Vector2 target_pos = root_pos + Vector2(
            Math::cos(final_angle) * radius,
            Math::sin(final_angle) * radius
        );
        
        layer[i]->set_position(target_pos);
    }
    
    queue_redraw();
}