from django.db import models
from skilltree.models import User
from django_fernet.fields import FernetTextField

class UserStravaIntegration( models.Model ):
    user = models.OneToOneField( User, on_delete=models.CASCADE )
    
    strava_access_token  = FernetTextField()
    strava_refresh_token = FernetTextField()
    
    strava_expires_at = models.DateTimeField()
    