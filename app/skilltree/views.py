from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from rest_framework import status
from .models import Tree, Node, ActionLog
from .serializers import TreeSerializer, NodeSerializer, RegistrySerializer
from .services import registry_service, login_service, action_service
import os
import json
from django.conf import settings


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def tree_view(request):
    trees = Tree.objects.filter( profile__user=request.user ).prefetch_related( 'nodes' )
    
    serializer = TreeSerializer( trees, many=True )
    
    return Response( serializer.data )    


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def habits_view(request):
    nodes = Node.objects.filter( tree__profile__user=request.user, node_type="H" )
    
    serializer = NodeSerializer( nodes, many=True )
    
    return Response( serializer.data )


@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    
    return login_service(request.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def history_view(request):
    user_profile = request.user.profile
    logs = ActionLog.objects.filter(profile=user_profile).select_related('node').order_by('-submitted_at')
    
    res = []
    for log in logs:
        res.append({
            "date": log.date.strftime("%Y-%m-%d"),
            "skill_id": log.node_id,
            "node_name": log.node.node_name,
            "progress_added": log.progress_added
        })
        
    return Response( res, status=status.HTTP_200_OK )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def action_view(request):
    return action_service( request.user, request.data )


@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def register_view(request):
    serializer = RegistrySerializer(data = request.data)
    
    return registry_service(serializer)


CATALOG_FILE = os.path.join( settings.BASE_DIR, 'skill', 'catalog.json' )

try:
    with open( CATALOG_FILE, 'r', encoding='utf-8') as f:
        CATALOG_DATA = json.load(f)
except Exception as ex:
    CATALOG_DATA = []
    print(f"Catalog loading error: {ex}")
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def catalog_view(request):
    return Response( CATALOG_DATA, status=status.HTTP_200_OK )