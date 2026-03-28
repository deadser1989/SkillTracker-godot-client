from django.db import models
from django.contrib.auth.models import AbstractUser
from django.core.validators import MaxValueValidator, MinValueValidator


class User( AbstractUser ):
    email = models.EmailField( max_length=128, unique=True, blank=False, null=False )
    password = models.CharField( max_length=64, blank=False, null=False )
    created_at = models.DateField( auto_now_add=True )
    
    
class Profile( models.Model ):
    user = models.ForeignKey( "User", on_delete=models.CASCADE )
    
    level  = models.BigIntegerField( default=1 )
    streak = models.BigIntegerField( default=0 )
    
    avatar_path = models.CharField() # ? maybe delete later
    
    
class Tree( models.Model ):
    profile = models.ForeignKey( "Profile", on_delete=models.CASCADE )
    
    theme = models.CharField( max_length=255, blank=False, null=False )
    
    updated_at = models.DateField( auto_now=True )
    created_at = models.DateField( auto_now_add=True )


class Node( models.Model ):
    HABIT = "H"
    ACTIVITY = "A"
    NODE_TYPES = [
        (HABIT, "Habit"),
        (ACTIVITY, "Activity"),
    ]
    
    DAILY = "D"
    WEEKLY = "W"
    MONTHLY = "M"
    COOLDOWN_CHOICES = {
        (DAILY, "Daily"),
        (WEEKLY, "Weekly"),
        (MONTHLY, "Monthly"),
    } 
    
    tree = models.ForeignKey( "Tree", on_delete=models.CASCADE )
    
    type     = models.CharField( max_length=1, choices=NODE_TYPES, blank=False, null=False )
    cooldown = models.CharField( max_length=1, choices=COOLDOWN_CHOICES, blank=False, null=False )
    
    submitted_at = models.DateField( auto_now=True )
    created_at   = models.DateField( auto_now_add=True )
    
    current_progress = models.IntegerField(
        validators=[
            MinValueValidator(0)
            ]
        )
    target_progress  = models.IntegerField(
        validators=[
            MinValueValidator(1),
            MaxValueValidator(1000000000)
            ]
        )