# Floor 404
## The Null Pointer

Πρώτο πρόσωπο liminal walking simulator σε εγκαταλελειμμένο εταιρικό όροφο. Ο σχεδιασμός για το **Level 4 (Abandoned Office / Corporate Complex)** είναι εμπνευσμένος από το *Escape the Backrooms*, *Dreamcore* και το *POOLS*. Η απουσία τεράτων εστιάζει όλη την εμπειρία στην **ατμόσφαιρα**, τη **γεωμετρία**, τον **ήχο** και την **αίσθηση απομόνωσης**.

**Επίσημος τίτλος:** Floor 404  
**Υπότιτλος:** The Null Pointer

Ακολουθούν οι **Αρχικές Οδηγίες Αρχιτεκτονικής & Σχεδιασμού** καθώς και τα **Prompts/Rules** που θα περάσεις στο **Cursor AI**.

---

# Α' Μέρος: Αρχιτεκτονική & Αρχές Σχεδιασμού (Design Document)

### 1. Αρχιτεκτονικό Στυλ & Ατμόσφαιρα (Level 4 - Corporate Office)

* **Δομή:** Ατελείωτοι διάδρομοι, αίθουσες συνεδριάσεων (meeting rooms), server rooms, cubicles, κουζίνες, τουαλέτες, αποθήκες, κλιμακοστάσια και ανελκυστήρες.
* **Παράθυρα & Εξωτερικό Περιβάλλον:** Τα παράθυρα βλέπουν στο απόλυτο σκοτάδι. Έξω ακούγεται καταρρακτώδης βροχή και αστραπές/κεραυνοί (οι κεραυνοί φωτίζουν στιγμιαία τα δωμάτια με παράθυρα). Δεν υπάρχει εξωτερικός κόσμος.
* **Κακόβουλοι Κίνδυνοι (Hazards without Monsters):**
* **Ηλεκτροπληξία:** Εκτεθειμένα καλώδια σε νερά ή κατεστραμμένους πίνακες - Not implement.
* **Πτώση στο Κενό:** Ασανσέρ που λείπουν, τρύπες στο πάτωμα που οδηγούν στο κενό - Not implement.


* **Instant Checkpoint System (Στυλ *POOLS*):** Όταν ο παίκτης πεθαίνει, η οθόνη μαυρίζει στιγμιαία (0.2 sec fade) και ο παίκτης γίνεται **instant respawn** στο τελευταίο ασφαλές σημείο/δωμάτιο (Checkpoint Zone) που πάτησε, διατηρώντας το immersion χωρίς loading screens.

### 2. Σύστημα Ασανσέρ (Vertical Navigation)

* Δεκάδες ανελκυστήρες διασκορπισμένοι σε πολλους ορόφους. Δυο ασανσερ ανα όροφο και 2 ηλεκτρολόγικοι πίνακες ανά όροφο, που πρεπει να επισκευαστούν - να λυθει ένας γρίφος - για να λειτουργουν τα εσωτερικά κουμπια που σε πηγαινουν σε άλλον όροφο.

### 3. Interaction & Audio System

* **Interaction (E key):** Άνοιγμα/κλείσιμο θυρών, διακοπτών φωτός, παραθύρων, κουμπιών ασανσέρ.
* **Dynamic Audio:**
* **Ambient:** Βόμβος φθορίου (Fluorescent hum), κλιματιστικά (HVAC noise), βροχή στα παράθυρα, μακρινές αστραπές.
* **Footsteps:** Διαφορετικοί ήχοι ανάλογα με την επιφάνεια (μοκέτα, πλακάκι, μάρμαρο, εκτεθειμένο τσιμέντο, νερό).



---

# Β' Μέρος: Οδηγίες για το Cursor AI

Για να καταλάβει το Cursor AI ακριβώς τι θέλεις να φτιάξει στη Godot 4, χωρίζουμε τις οδηγίες σε **System Rules** (`.cursorrules`) και **Specific Feature Prompts**.

---

### 1. Αρχείο `.cursorrules` (System Context)

Δημιούργησε ένα αρχείο με όνομα `.cursorrules` στην ρίζα του Workspace σου στο Cursor και επικόλλησε το παρακάτω:

```text
# GODOT 4 GAME DEVELOPMENT RULES (FLOOR 404)

Project Context:
- Title: Floor 404 — The Null Pointer
- Engine: Godot 4.x (GDScript)
- Game Type: First-Person Liminal Space Walking Simulator (Backrooms Level 4 style)
- Target Aesthetics: Atmospheric, abandoned corporate office, dark windows with thunder/rain outside.
- Core Mechanics: WASD movement, Smooth Mouse Look, Interaction with doors/switches (E key), Instant Respawn Hazards, Elevator Teleports.
- NO Monsters, NO HUD, NO Weapons, NO Visible Player Mesh.

Coding Guidelines:
1. Use strict Godot 4 syntax (@export, @onready, CharacterBody3D, Node3D, Area3D, RayCast3D). Do NOT use Godot 3 syntax.
2. Code must be modular, well-commented, and optimized for performance.
3. Keep scripts clean and readable. Use Signals for decoupling events (e.g. player_died, interact_triggered).

```

---

### 2. Prompts για Παραγωγή Κώδικα στο Cursor AI

Μπορείς να δίνεις στο Cursor AI τα παρακάτω prompts **ένα-ένα** για να σου δημιουργεί τα αντίστοιχα GDScript αρχεία:

#### 🤖 PROMPT 1: First-Person Controller + Interaction System

> **Prompt:**
> "Create a complete First-Person Controller script (`player.gd`) for Godot 4 (`CharacterBody3D`).
> Features required:
> 1. Classic WASD movement with smooth acceleration and friction.
> 2. Smooth mouse look with clamped vertical rotation (looking up/down).
> 3. Head Bobbing effect when walking.
> 4. Footstep Audio Manager using RayCast3D to detect floor material (carpet, tile, metal, water).
> 5. RayCast3D Interaction System using 'E' key to interact with objects that have an `interact()` method (doors, switches, elevator buttons).
> 6. NO jumping, NO visible player mesh/body.
> Provide the full GDScript code."
> 
> 

---

#### 🤖 PROMPT 2: Instant Respawn / Checkpoint Hazard System

> **Prompt:**
> "Create a Checkpoint System for Godot 4 (*POOLS* style instant respawn).
> Requirements:
> 1. A `CheckpointZone.gd` (`Area3D`) script that updates the Player's `last_safe_position` when entered.
>
> Write the script for`CheckpointZone.gd`, and the required code integration for `player.gd`."
> 
> 

---

#### 🤖 PROMPT 3: Interactive Door & Switch Mechanics

> **Prompt:**
> "Create interactive object scripts for Godot 4:
> 1. `Door.gd` (`Node3D` / `AnimatableBody3D`): Opens/closes smoothly when interacted with ('E' key), plays open/close audio, and can be locked.
> 2. `LightSwitch.gd`: Toggles connected `OmniLight3D`/`SpotLight3D` nodes on/off with a click sound.
> 3. Both scripts must implement an `interact()` function that the player's RayCast3D can call."
> 
> 

---

#### 🤖 PROMPT 4: Non-Euclidean Elevator Teleport System

> **Prompt:**
> "Create an Elevator System in Godot 4 for moving vertically between maze sections.
> Requirements:
> 1. An Elevator room with interactive door and floor buttons..
> 2. Open the doors to reveal the new maze area."
> 
> 

---
