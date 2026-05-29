from django.db import models
from django.contrib.auth.models import AbstractUser
from django.core.validators import MaxValueValidator, MinValueValidator
from django.utils import timezone


class User( AbstractUser ):
    username = models.CharField( max_length=120, unique=True, blank=False, null=False )
    created_at = models.DateField( auto_now_add=True )
    
    
class Profile( models.Model ):
    user = models.OneToOneField( "User", on_delete=models.CASCADE, related_name='profile' )
    
    level  = models.BigIntegerField( default=1 )
    streak = models.BigIntegerField( default=0 )
    
    avatar_path = models.CharField(max_length=255, blank=True, null=True)
    
    
class Tree( models.Model ):
    AREA_READING = 0
    AREA_FITNESS = 1
    AREA_LANGUAGE = 2
    AREA_CREATIVITY = 3
    AREA_CUSTOM = 4
    AREA_CHOICES = [
        (AREA_READING, "Reading"),
        (AREA_FITNESS, "Fitness"),
        (AREA_LANGUAGE, "Language"),
        (AREA_CREATIVITY, "Creativity"),
        (AREA_CUSTOM, "Custom"),
    ]
    
    profile = models.ForeignKey( "Profile", on_delete=models.CASCADE, related_name='trees' )
    
    area = models.IntegerField( default=4, choices=AREA_CHOICES, blank=False, null=False )
    verbose_title = models.CharField( default="", max_length=255, blank=False, null=False )
    
    updated_at = models.DateField( auto_now=True )
    created_at = models.DateField( auto_now_add=True )
    
    def save( self, *args, **kwargs):
        if self.area != self.AREA_CUSTOM:
            preset_title = dict(self.AREA_CHOICES).get(self.area)
            self.verbose_title = preset_title
        
        super().save(*args, **kwargs)
        

class ActionLog( models.Model ):
    profile = models.ForeignKey("Profile", on_delete=models.CASCADE, related_name='action_logs')
    node = models.ForeignKey("Node", on_delete=models.CASCADE, related_name='action_logs')
    
    progress_added = models.IntegerField(
        default=0,
        validators=[
            MinValueValidator(0),
            MaxValueValidator(1000000000),
        ],
        blank=False,
        null=False
    )
    submitted_at = models.DateField(auto_now_add=True)


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
    COOLDOWN_CHOICES = [
        (DAILY, "Daily"),
        (WEEKLY, "Weekly"),
        (MONTHLY, "Monthly"),
    ]
    
    STATE_HIDDEN = 0
    STATE_REVEALED = 1
    STATE_ACTIVE = 2
    STATE_FINISHED = 3
    STATE_CHOICES = [
        (STATE_HIDDEN, "Hidden"),
        (STATE_REVEALED, "Revealed"),
        (STATE_ACTIVE, "Active"),
        (STATE_FINISHED, "Finished"),
    ]
    
    RARITY_COMMON = 0
    RARITY_RARE = 1
    RARITY_EPIC = 2
    RARITY_LEGENDARY = 3
    RARITY_CHOICES = [
        (RARITY_COMMON, "Common"),
        (RARITY_RARE, "Rare"),
        (RARITY_EPIC, "Epic"),
        (RARITY_LEGENDARY, "Legendary"),
    ]
    
    tree = models.ForeignKey( "Tree", on_delete=models.CASCADE, related_name='nodes' )
    
    node_name   = models.CharField( default="", max_length=64, blank=False, null=False )
    node_info   = models.CharField( default="", max_length=64, blank=False, null=False )
    node_type   = models.CharField( default="A", max_length=1, choices=NODE_TYPES, blank=False, null=False )
    node_state  = models.IntegerField( default=2, choices=STATE_CHOICES, blank=False, null=False )
    node_rarity = models.IntegerField( default=0, choices=RARITY_CHOICES, blank=False, null=False )
    node_level  = models.IntegerField( default=1, blank=False, null=False )
    
    parent = models.ForeignKey( 'self',
                               blank=True,
                               null=True,
                               related_name='children',
                               on_delete=models.CASCADE )
    xp_reward = models.IntegerField( default=0, blank=False, null=False )
    cooldown  = models.CharField( max_length=1, choices=COOLDOWN_CHOICES, blank=True, null=True )
    
    submitted_at = models.DateField( auto_now=True )
    created_at   = models.DateField( auto_now_add=True )
    expires_at   = models.DateField( blank=True, null=True )
    
    icon_path = models.CharField( blank=True, null=True )
    
    current_progress = models.IntegerField(
        default=0,
        validators=[
            MinValueValidator(0)
            ],
        blank=False,
        null=False
        )
    target_progress  = models.IntegerField(
        default=1,
        validators=[
            MinValueValidator(1),
            MaxValueValidator(1000000000)
            ],
        blank=False,
        null=False
        )
        
