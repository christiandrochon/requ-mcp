# language: fr
@api @US-125 @REQ-125
Fonctionnalité: Suggestion de doublage timbral et harmonisation de guitares jumelles

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/ArrangementController.java:109 ; lyra-ml/app/main.py:2900 ; arrangement.py:131-175 (DIATONIC_SIXTH_STEPS = 5 degrés)
  @AC-1 @api
  Scénario: Chaque note de la seconde ligne est 5 degrés de la gamme au-dessus (ou au-dessous si demandé)
    Quand j'envoie POST "/api/arrange/doublage-sixte-diatonique" avec le corps JSON :
      """
      {"motif": [{"pitch":60,"duree_temps":1},{"pitch":62,"duree_temps":1},{"pitch":64,"duree_temps":1}],
       "instrument": "guitare électrique (6 cordes)", "mode": "ionien", "tonique": "Do", "au_dessus": true}
      """
    Alors la réponse a le statut 200
    Et les hauteurs de "notes" valent [69, 71, 72]
    Quand j'envoie POST "/api/arrange/doublage-sixte-diatonique" avec le même motif et "au_dessus" false
    Alors les hauteurs de "notes" valent [52, 53, 55]

  # réf: lyra-api/generation/ArrangementController.java:109 ; lyra-ml/app/main.py:2900
  @AC-2 @api
  Scénario: En do majeur, Do→La (9 demi-tons) puis La→Fa (8 demi-tons)
    Quand j'envoie POST "/api/arrange/doublage-sixte-diatonique" avec le corps JSON :
      """
      {"motif": [{"pitch":60,"duree_temps":1},{"pitch":69,"duree_temps":1}],
       "instrument": "guitare électrique (6 cordes)", "mode": "ionien", "tonique": "Do"}
      """
    Alors la réponse a le statut 200
    Et les hauteurs de "notes" valent [69, 77]

  # réf: lyra-api/generation/ArrangementController.java:35 ; lyra-ml/app/main.py:1557 ; ArrangementController.java:35, 109
  @AC-3 @api
  Scénario: Le choix tierces/sixtes reste explicite : aucune bascule automatique
    Quand j'envoie POST "/api/arrange/suggest" avec le corps JSON :
      """
      {"motif": [{"pitch":60,"duree_temps":1},{"pitch":62,"duree_temps":1}], "mode": "ionien", "tonique": "Do", "pitch_min": 55, "pitch_max": 84}
      """
    Alors la réponse a le statut 200
    # A CONFIRMER : preuve de la négative (« aucune bascule ») : on vérifie seulement que la suggestion générale reste en tierces + octave et ne contient pas de sixte
    Et les hauteurs de "doublage_tierces.notes" ne contiennent pas les sixtes diatoniques [69, 71]
