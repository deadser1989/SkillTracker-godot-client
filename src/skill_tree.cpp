#include "skill_tree.hpp"
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void SkillTree::_bind_methods() {
    ClassDB::bind_method(D_METHOD("reveal_successors", "skill_node"), &SkillTree::reveal_successors);
}

SkillTree::SkillTree() {}
SkillTree::~SkillTree() {}

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
            
            if (parent_node && parent_node->getState() != SkillNode::STATE_HIDDEN) { //если родитель не скрыт рисуем линию
                draw_line(
                current->get_global_position(),
                parent_node->get_global_position(),
                Color(0.8, 0.5, 0.9, 0.9),
                1.0,
                true);
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
            if (!parent || parent->getState() != SkillNode::STATE_FINISHED) {
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

    if (node_map.has(id)) {
        UtilityFunctions::print("Duplicate skill id: ", id);
        return;
    }

    node_map[id] = node;
}

