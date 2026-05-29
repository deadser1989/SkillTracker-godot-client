import os 
import requests
from .models import UserStravaIntegration
from datetime import datetime


def get_strava_token_service( code ):
    client_secret = os.environ.get( 'STRAVA_CLIENT_SECRET' )
    client_id     = os.environ.get( 'STRAVA_CLIENT_ID' )
    
    response = requests.post( url="https://www.strava.com/oauth/token", 
        data={
            'client_id': client_id,
            'client_secret' : client_secret,
            'code': code,
            'grant_type': 'authorization_code',
            'redirect_uri': 'http://localhost:3000/strava-callback',
        })

    return response.json


def apply_tokens_service( user, token_data ):
    integration, created = UserStravaIntegration.objects.update_or_create(
        user=user,
        defaults={
            'strava_access_token': token_data.get('access_token'),
            'strava_refresh_token' : token_data.get('refresh_token'),
            'strava_expires_at' : datetime.fromtimestamp( token_data.get('expires_at') ),
        }
    )
    
    return integration


def fetch_strava_activities( user ):
    try:
        user = UserStravaIntegration.objects.get( user=user )
    except UserStravaIntegration.DoesNotExist:
        return {"error": "Integration not found"}, 404
    
    access_token = user.strava_access_token
    headers = {
        'Authorization': f'Bearer {access_token}'
    }
    
    response = requests.get( "https://www.strava.com/api/v3/athlete/activities", headers=headers )
    
    if response.status_code != 200:
        return {"error": "Failed to fetch data from Strava"}, response.status_code
    
    simplified = []
    activities = response.json
    for activity in activities:
        simplified.append({
            "id": activity.get("id"),
            "name": activity.get("name"),
            "type": activity.get("type"),
            "distance_km": round(activity.get("distance", 0) / 1000, 2),
            "duration_minutes": round(activity.get("moving_time", 0) / 60, 1),
            "start_date": activity.get("start_date_local"),
        })
        
    return simplified, 200 