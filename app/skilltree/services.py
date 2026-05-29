import os
import json
import random
from django.conf import settings
from django.db import transaction
from django.shortcuts import get_object_or_404
from rest_framework.response import Response
from rest_framework import status
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate

from .models import Profile, Node, ActionLog, Tree

def _roll_skills_from_catalog(profile, area, count):
    catalog_file = os.path.join(settings.BASE_DIR, 'skill', 'catalog.json')
    try:
        with open(catalog_file, 'r', encoding='utf-8') as f:
            catalog_data = json.load(f)
    except Exception:
        catalog_data = []

    available_pool = [item for item in catalog_data if item.get('area') == area]
    existing_names = set(Node.objects.filter(tree__profile=profile).values_list('node_name', flat=True))
    fresh_pool = [item for item in available_pool if item.get('node_name') not in existing_names]
    final_pool = fresh_pool if fresh_pool else available_pool
    
    if not final_pool:
        return [{"node_name": f"Навык {random.randint(10,99)}", "node_info": "Описание"}] * count

    return random.sample(final_pool, min(count, len(final_pool)))


def registry_service(serializer) -> Response:
    if serializer.is_valid():
        try:
            with transaction.atomic():
                user = serializer.save()
                profile = Profile.objects.create(user=user, level=1, streak=0)
                token, _ = Token.objects.get_or_create(user=user)
                
                starter_branches = [
                    {"area": Tree.AREA_READING,    "name": "ЧТЕНИЕ"},
                    {"area": Tree.AREA_FITNESS,    "name": "СПОРТ"},
                    {"area": Tree.AREA_LANGUAGE,   "name": "ЯЗЫКИ"},
                    {"area": Tree.AREA_CREATIVITY, "name": "ТВОРЧЕСТВО"},
                ]
                
                for branch in starter_branches:
                    tree = Tree.objects.create(profile=profile, area=branch["area"])
                    
                    root_node = Node.objects.create(
                        tree             = tree,
                        parent           = None,
                        node_name        = branch["name"],
                        node_info        = "Дефолт",
                        node_state       = Node.STATE_ACTIVE,
                        node_level       = 1,
                        node_rarity      = Node.RARITY_COMMON,
                        xp_reward        = 10,
                        current_progress = 0,
                        target_progress  = 5,
                    )
                    
                    rolled_items = _roll_skills_from_catalog(profile, branch["area"], 2)
                    for item in rolled_items:
                        Node.objects.create(
                            tree             = tree,
                            parent           = root_node,
                            node_name        = item.get('node_name', 'Новый навык'),
                            node_info        = item.get('node_info', 'Ожидает изучения'),
                            node_state       = Node.STATE_REVEALED, 
                            node_level       = 1,
                            node_rarity      = int(item.get('node_rarity', 0)),
                            xp_reward        = int(item.get('xp_reward', 15)),
                            current_progress = 0,
                            target_progress  = int(item.get('base_progress', 5))
                        )

            return Response({"message": "Success", "user_id": user.pk, "token": token.key}, status=status.HTTP_201_CREATED)
        except Exception as ex:
            return Response({"error": str(ex)}, status=status.HTTP_400_BAD_REQUEST)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


def add_node_service(user, request_data) -> Response:
    try:
        parent_node = get_object_or_404(Node, id=request_data.get('parent_id'), tree__profile=user.profile)
        new_node = Node.objects.create(
            tree=parent_node.tree,
            parent=parent_node,
            node_name=request_data.get('node_name'),
            node_info=request_data.get('node_info'),
            node_state=Node.STATE_REVEALED, 
            node_level=1,
            node_rarity=request_data.get('node_rarity', 0),
            xp_reward=request_data.get('xp_reward', 10),
            current_progress=0,
            target_progress=request_data.get('target_progress', 1),
            cooldown=request_data.get('cooldown', 'D')
        )
        return Response({"status": "success", "new_node_id": new_node.id}, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

def activate_node_service(user, request_data) -> Response:
    node = get_object_or_404(Node, id=request_data.get('skill_id'), tree__profile=user.profile)
    node.node_state = Node.STATE_ACTIVE
    node.save()
    return Response({"status": "success", "node_state": node.node_state}, status=status.HTTP_200_OK)


def action_service(user, request_data) -> Response:
    node = get_object_or_404(Node, id=request_data.get('skill_id'), tree__profile=user.profile)
    
    if request_data.get('is_levelup'):
        node.node_level += 1
        node.current_progress = 0
        node.target_progress = int(request_data.get('new_target', node.target_progress))
        node.node_state = Node.STATE_ACTIVE
        node.save()
        return Response({"status": "level_up"}, status=status.HTTP_200_OK)
        
    added_progress = int(request_data.get('added_progress', 0))
    node.current_progress += added_progress
    
    if node.current_progress >= node.target_progress:
        node.current_progress = node.target_progress
        node.node_state = Node.STATE_FINISHED
        user.profile.level += node.xp_reward
        user.profile.save()
        
    node.save()
    if added_progress > 0:
        ActionLog.objects.create(profile=user.profile, node=node, progress_added=added_progress)
        
    return Response({"status": "success", "current_progress": node.current_progress, "node_state": node.node_state}, status=status.HTTP_200_OK)

def login_service(request_data) -> Response:
    user = authenticate(username=request_data.get('username'), password=request_data.get('password'))
    if not user: return Response({"error":"Invalid login data"}, status=status.HTTP_400_BAD_REQUEST)
    token, _ = Token.objects.get_or_create(user=user)
    return Response({'token': token.key, 'user_id': user.pk}, status=status.HTTP_200_OK)