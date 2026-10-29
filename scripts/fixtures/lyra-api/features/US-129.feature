# language: fr
@api @US-129 @REQ-129
Fonctionnalité: Contrepoint (cinq espèces et N voix) sur cantus firmus

  Contexte:
    Soit l'API Lyra joignable
    Et un cantus firmus en ré dorien de 11 notes de 4 temps : 62 65 64 62 67 65 69 67 65 64 62

  # réf: lyra-api/generation/GenerationController.java:417 ; lyra-ml/app/main.py:1161 ; contrepoint.py:206-226
  @AC-1 @api
  Scénario: 1re espèce : même longueur, aucune quinte/octave parallèle, débute et finit sur consonance parfaite
    Quand j'envoie POST "/api/generate/contrepoint-premiere-espece" avec le cantus firmus, "mode" "dorien", "tonique" "Ré", "au_dessus" true et "random_seed" 4
    Alors la réponse a le statut 200
    Et "result.contrepoint" contient autant de notes que "result.cantus_firmus"
    Et aucune quinte ni octave parallèle n'existe entre "result.contrepoint" et "result.cantus_firmus"
    Et l'intervalle initial et l'intervalle final entre les deux lignes sont un unisson, une quinte ou une octave (modulo 12 dans {0, 7})

  # réf: lyra-api/generation/GenerationController.java:417 ; lyra-ml/app/main.py:1161 ; GenerationController.java:417-428
  @AC-2 @api
  Scénario: Chaque note porte une décision listant les candidats exclus avec la règle ; décisions persistées avec un requestId
    Quand j'envoie POST "/api/generate/contrepoint-premiere-espece" avec le cantus firmus, "mode" "dorien", "tonique" "Ré", "au_dessus" true et "random_seed" 4
    Alors la réponse a le statut 200
    Et "result.decisions" contient autant d'éléments que "result.contrepoint"
    Et chaque élément de "result.decisions" a une liste "alternatives" dont chaque élément a "raison_rejet" non vide
    Et le champ "requestId" est un UUID
    # RÉSOLU : vérification SQL directe sur generation_decision (colonne request_id) via la base de la pile de test (POSTGRES_PORT).
    Et la table "generation_decision" contient au moins autant de lignes pour ce requestId que de décisions

  # réf: lyra-api/generation/GenerationController.java:495 ; lyra-ml/app/main.py:1262 ; contrepoint.py:277-311
  @AC-3 @api
  Scénario: Contrepoint à N voix : une voix ajoutée par position, en plus du cantus firmus
    Quand j'envoie POST "/api/generate/contrepoint-a-n-voix" avec le cantus firmus, "mode" "dorien", "tonique" "Ré", "positions" [true, false] et "random_seed" 4
    Alors la réponse a le statut 200
    Et la liste "result.voix" contient 2 éléments
    Et le champ "result.cantus_firmus" est non vide
