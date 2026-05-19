from rest_framework import serializers
from .models import Tree, Node, User


class NodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Node
        
        fields = [
            'id', 'parent',
            'node_name', 'node_info', 'node_type',  'node_state', 'node_rarity', 'node_level',
            'xp_reward', 'cooldown',
            'submitted_at','created_at', 'expires_at',
            'current_progress', 'target_progress',
            'icon_path'
        ]


class TreeSerializer(serializers.ModelSerializer):
    nodes = NodeSerializer( many=True, read_only=True )
    
    class Meta:
        model = Tree
        
        fields = [
            'id', 'area', 'verbose_title',
            'updated_at', 'created_at', 'nodes'
        ]

class RegistrySerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['username', 'email', 'password']
        extra_kwargs = {'password': {'write_only': True}}
        
    def create(self, validated_data):
        return User.objects.create_user( **validated_data )