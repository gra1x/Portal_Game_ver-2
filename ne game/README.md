# 3D FPS Portal Game

A first-person shooter game built in Godot 4.4.1 featuring Portal-style mechanics with advanced enemy AI and platformer elements.

## 🎮 Game Overview

This is a 3D FPS game that combines traditional shooting mechanics with Portal-style teleportation gameplay. Fight enemies across multi-level platforms while using a dual-weapon system including a Portal Gun that creates linked teleportation portals.

## ✨ Features

### Core Gameplay
- **First-Person Shooter Mechanics**: Traditional FPS movement, shooting, and combat
- **Dual Weapon System**: Switch between regular gun and Portal Gun
- **Portal Mechanics**: Create blue and orange portals for teleportation (Portal game style)
- **3D Platformer Elements**: Multi-level platforms with jumping mechanics
- **Enemy AI System**: Intelligent enemies with patrol, chase, attack, and search behaviors

### Weapon Systems
- **Regular Gun**: 
  - 30 rounds per magazine
  - Bullet damage to enemies
  - Zoom/aim functionality
  - Muzzle flash effects
  - Reload system

- **Portal Gun**:
  - Left click: Create blue portals
  - Right click: Create orange portals
  - Unique muzzle flash effects (cyan/orange)
  - Instant teleportation between paired portals
  - Works on static surfaces only

### Enemy AI
- **Advanced State Machine**: Patrol → Chase → Attack → Search states
- **Line of Sight Detection**: Enemies can spot and track the player
- **Obstacle Avoidance**: Smart pathfinding around level geometry
- **Portal Usage**: Enemies can go through portals and reset AI behavior
- **Combat System**: Melee attacks with proper timing and animations

### Pickup & Resource System
- **Health Pickups**: Red glowing crosses that restore 25 health points
- **Ammo Pickups**: Yellow glowing cylinders that restore 15 ammo rounds
- **Strategic Placement**: Pickups placed on platforms and key locations
- **Respawn System**: Pickups automatically respawn after 10 seconds
- **Visual Effects**: Floating animation, rotation, and collection effects
- **Smart Collection**: Only collectable when resources are not at maximum

### Movement Enhancement
- **Jump Pads**: Cyan glowing cylindrical launch pads
- **Variable Force**: Different pads provide 12-18 force levels
- **Visual Feedback**: Pulsing animation and launch flash effects
- **Universal Usage**: Works for both players and enemies
- **Cooldown System**: 0.5-second cooldown to prevent spam

### Game Modes
- **Standard Mode**: Classic FPS with all features enabled
- **Target Practice**: Timed accuracy challenge with 20 floating targets
- **Wave Survival**: Endless enemy waves with increasing difficulty
- **Mode Selection**: Choose from main menu with dedicated buttons
- **High Score Tracking**: Performance tracking for each mode

### UI & Menus
- **Enhanced Main Menu**: Three game mode options plus settings
- **HUD System**: Health, ammo, score tracking with visual indicators
- **Death Screen**: Respawn system with performance ratings
- **Pause Menu**: In-game escape menu with options
- **Fullscreen Support**: F11 toggle with responsive UI scaling

## 🎯 Controls

### Movement
- **W/A/S/D**: Move forward/left/backward/right
- **Mouse**: Look around (captured cursor)
- **Space**: Jump
- **Escape**: Pause menu

### Combat
- **Left Click**: Shoot (bullets with regular gun, blue portals with Portal Gun)
- **Right Click**: Aim with regular gun / Create orange portals with Portal Gun
- **Key "2"**: Switch between regular gun and Portal Gun
- **R**: Reload regular gun

### System
- **F11**: Toggle fullscreen
- **Escape**: Pause/unpause game

## 🚀 How to Run

1. **Requirements**: Godot 4.4.1 or later
2. **Setup**: Open the project in Godot Engine
3. **Play**: Press F5 or click "Play" button in Godot
4. **Build**: Use Godot's export templates for standalone builds

## 🛠️ Technical Features

### Graphics & Visuals
- **3D Rendering**: Full 3D environment with dynamic lighting
- **Portal Effects**: Animated portal rings with emission materials
- **Muzzle Flash**: Dynamic light effects for weapon firing
- **Enemy Animations**: Walking cycles and attack animations
- **UI Scaling**: Responsive interface for different screen sizes

### Physics & Movement
- **Character Controller**: Smooth FPS movement with gravity
- **Portal Physics**: Velocity preservation through teleportation
- **Collision Detection**: Accurate raycast-based hit detection
- **Platforming**: Reliable jumping and multi-level navigation

### AI & Gameplay Systems
- **State-Based AI**: Clean state machine for enemy behaviors
- **Spawn System**: Dynamic enemy spawning around the arena
- **Score System**: Points for enemy elimination
- **Health System**: Player health with visual feedback

## 📝 Recent Updates

### Latest Version Features:
- ✅ **Portal Gun Implementation**: Full Portal-style mechanics with blue/orange portals
- ✅ **Weapon Switching**: Seamless switching between regular gun and Portal Gun (Key "2")
- ✅ **Enemy Portal Usage**: Enemies can walk through portals and teleport
- ✅ **Enhanced Muzzle Effects**: Unique visual effects for each weapon type
- ✅ **Respawn System Fix**: Eliminated game freezing issues during respawn
- ✅ **AI Portal Integration**: Enemies reset behavior intelligently after teleportation
- ✅ **Health/Ammo Pickups**: Strategic resource pickups with respawn system
- ✅ **Jump Pads**: Cyan glowing launch pads with varying force levels
- ✅ **Game Mode System**: Multiple game modes with unique objectives
- ✅ **Target Practice Mode**: Accuracy training with floating targets
- ✅ **Wave Survival Mode**: Endless enemy waves with increasing difficulty
- ✅ **Enhanced Menu System**: Game mode selection and improved options

### Game Mechanics Progression:
1. **Basic FPS Core**: Movement, shooting, enemy AI
2. **Platformer Elements**: Multi-level platforms, jumping mechanics
3. **Advanced Enemy AI**: Improved movement system, obstacle avoidance
4. **Portal System**: Complete Portal Gun implementation
5. **Dual Weapon System**: Weapon switching with visual feedback
6. **Portal AI Integration**: Enemies can use portals strategically

## 🎲 Gameplay Tips

- **Portal Strategy**: Use portals to escape enemy chases or redirect their paths
- **Weapon Selection**: Switch to Portal Gun for mobility, regular gun for combat
- **Enemy Behavior**: Enemies lose track temporarily after portal teleportation
- **Platform Usage**: Use height advantage and portals for tactical positioning
- **Resource Management**: Monitor ammo and health, use respawn strategically

## 🔧 Development Notes

Built with Godot 4.4.1 using GDScript. Features modular design with separate scripts for:
- Player controller and weapon systems
- Enemy AI with state machine
- Portal mechanics and teleportation
- UI and menu systems
- Game management and spawning

The game demonstrates advanced 3D game development concepts including physics-based movement, AI state machines, dynamic UI systems, and complex gameplay mechanics integration.

---

**Last Updated**: January 26, 2025
**Version**: Portal Integration Complete
**Engine**: Godot 4.4.1
