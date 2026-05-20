from django.urls import path
from integrations.views import strava_callback_view, activities_view

urlpatterns = [
    path('auth/strava-callback', view=strava_callback_view, name='strava_callback'),
    path('activities/', view=activities_view, name='strava_activities')
]
