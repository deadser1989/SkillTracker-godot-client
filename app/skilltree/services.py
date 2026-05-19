from rest_framework.response import Response
from rest_framework import status
from rest_framework.authtoken.models import Token
from .models import Profile, Node, ActionLog, Tree
from django.db import transaction
from django.contrib.auth import authenticate
from django.shortcuts import get_object_or_404


def registry_service(serializer) -> Response:
    if serializer.is_valid():
        try:
            with transaction.atomic():
                user = serializer.save()
                profile = Profile.objects.create(
                    user   = user,
                    level  = 1,
                    streak = 0
                )
                
                starter_branches = [
                    {"area": Tree.AREA_READING,    "name": "ЧТЕНИЕ"},
                    {"area": Tree.AREA_FITNESS,    "name": "СПОРТ"},
                    {"area": Tree.AREA_LANGUAGE,   "name": "ЯЗЫКИ"},
                    {"area": Tree.AREA_CREATIVITY, "name": "ТВОРЧЕСТВО"},
                ]
                
                for branch in starter_branches:
                    tree = Tree.objects.create(
                        profile = profile,
                        area    = branch["area"]
                    )
                    
                    Node.objects.create(
                        tree             = tree,
                        parent           = None,
                        node_name        = branch["name"],
                        node_info        = "Дефолт",
                        node_state       = Node.STATE_FINISHED,
                        node_level       = 1,
                        node_rarity      = Node.RARITY_COMMON,
                        xp_reward        = 10,
                        current_progress = 1,
                        target_progress  = 1,
                    )

            return Response(
                {
                    "message": "User, profile and starter trees created successfully.",
                    "user_id": user.pk
                },
                status=status.HTTP_201_CREATED
            )
        except Exception as ex:
            return Response({"error": str(ex)}, status=status.HTTP_400_BAD_REQUEST)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
                

def login_service( request_data ) -> Response:
    username = request_data.get('username')
    password = request_data.get('password')
    
    user = authenticate( username=username, password=password )
    
    if not user:
        return Response({"error":"Invalid login data"}, status=status.HTTP_400_BAD_REQUEST)
    
    token, _ = Token.objects.get_or_create(user=user)
    return Response({
        'token': token.key,
        'user_id': user.pk
    }, status=status.HTTP_200_OK )
    

def action_service( user, request_data ) -> Response:
    node_id = request_data.get('skill_id')
    added_progress = request_data.get('added_progress')
    if node_id is None or added_progress is None:
        return Response({"error":"Missing skill_id or added_progress"}, status=status.HTTP_400_BAD_REQUEST)
    try: 
        added_progress = int(added_progress)
    except ValueError:
        return Response({"error":"added_progress must be an integer"}, status=status.HTTP_400_BAD_REQUEST)
    
    user_profile = user.profile
    node = get_object_or_404( Node, id=node_id, tree__profile=user_profile )
    if node.node_state == Node.STATE_FINISHED:
        return Response( {"error": "This node is already finished"}, status=status.HTTP_400_BAD_REQUEST )
    
    node.current_progress += added_progress
    
    node_just_finished = False
    if node.current_progress >= node.target_progress:
        node.current_progress = node.target_progress
        node.node_state = Node.STATE_FINISHED
        node_just_finished = True
        
        user_profile.level += node.xp_reward
        user_profile.save()
    
    node.save()
    
    ActionLog.objects.create(
        profile = user_profile,
        node = node,
        progress_added = added_progress
    )
        
    return Response({
        "status": "success",
        "node_id": node.id,
        "current_progress": node.current_progress,
        "target_progress": node.target_progress,
        "node_state": node.node_state,
        "node_just_finished": node_just_finished,
        "profile_level": user_profile.level
    }, status=status.HTTP_200_OK)
    
    
def history_service( user ) -> Response:
    user_profile = user.profile
    logs = ActionLog.objects.filter(profile=user_profile).select_related('node').order_by('-date')
    
    res = []
    for log in logs:
        res.append({
            "date": log.date.strftime("%Y-%m-%d"),
            "skill_id": log.node_id,
            "node_name": log.node.node_name,
            "progress_added": log.progress_added
        })
        
    return Response( res, status=status.HTTP_200_OK )