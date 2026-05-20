from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from rest_framework import status
from .services import get_strava_token_service, apply_tokens_service, fetch_strava_activities


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def strava_callback_view( request ):
    code = request.get('code')
    if not code:
        return Response({"error": "No code provided"}, status=status.HTTP_400_BAD_REQUEST)
    
    tokens = get_strava_token_service( code )
    if 'access_token' not in tokens:
        return Response({"error": "Failed to fetch tokens"}, status=status.HTTP_400_BAD_REQUEST)
    
    apply_tokens_service( request.user, tokens )
    
    return Response({"status": "OK"}, status=status.HTTP_200_OK)
    
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def activities_view( request ):
    data, status_code = fetch_strava_activities( request.user )
    
    if status_code != 200:
        return Response( data, status=status_code )
    
    return Response( data, status=status.HTTP_200_OK )