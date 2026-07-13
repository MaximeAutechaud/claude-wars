class_name Spells

# Pool de sorts de héros. Un sort appris à chaque niveau (choix entre deux).
# "range" en cases hex ; "cooldown" en tours (décompté au début du tour du camp).
# "free": true → n'épuise pas l'attaque du tour (sorts utilitaires) ;
# false → consomme l'action comme une attaque (gros sorts).
# Dans tous les cas : un seul sort par tour (Unit.has_cast).
const POOL: Dictionary = {
	"heal": {
		"name": "Soin", "range": 2, "cooldown": 3, "free": false,
		"desc": "Rend 6 PV à un allié (portée 2)",
	},
	"fireball": {
		"name": "Boule de feu", "range": 3, "cooldown": 4, "free": false,
		"desc": "4 dégâts en zone, alliés compris (portée 3, rayon 1)",
	},
	"blink": {
		"name": "Bond", "range": 3, "cooldown": 3, "free": true,
		"desc": "Saute sur une case libre en ignorant tout (portée 3)",
	},
	"warcry": {
		"name": "Cri de guerre", "range": 0, "cooldown": 4, "free": true,
		"desc": "+2 atk aux alliés à 2 cases jusqu'au prochain tour",
	},
}

const HEAL_AMOUNT     := 6
const FIREBALL_DAMAGE := 4
const FIREBALL_RADIUS := 1
const WARCRY_BONUS    := 2
const WARCRY_RADIUS   := 2
