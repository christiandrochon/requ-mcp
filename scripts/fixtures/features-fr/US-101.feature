# language: fr
@api @US-101 @REQ-101
Fonctionnalité: Enrichir une progression par emprunts modaux, dominantes secondaires et médiantes chromatiques

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/generation/GenerationController.java:53 ; lyra-ml/app/main.py:1017 ; champ degres_emprunt_autorises : ChordProgressionRequestDto.java
  @AC-3 @api
  Plan du Scénario: Les accords empruntés respectent la liste de degrés autorisés (graine <graine>)
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 110, "mode": "ionien", "tonique": "Do", "nombre_mesures": 16,
       "autoriser_emprunts": true, "degres_emprunt_autorises": ["bVII", "bVI"], "random_seed": <graine>}
      """
    Alors la réponse a le statut 200
    # RÉSOLU (code) : roman_numeral = étiquette de BORROWED_CHORD_OPTIONS (diatonic.py build_borrowed_chord, roman_numeral=degree_label).
    Et tout accord où "est_emprunt" vaut true a "roman_numeral" dans la liste ["bVII", "bVI"]

    Exemples:
      | graine |
      | 1      |
      | 2      |
      | 3      |
      | 4      |
      | 5      |

  # réf: lyra-api/generation/GenerationController.java:53 ; lyra-ml/app/main.py:1017
  @AC-4 @api
  Plan du Scénario: Toutes les techniques désactivées : aucun accord coloré (graine <graine>)
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 110, "mode": "ionien", "tonique": "Do", "nombre_mesures": 16,
       "autoriser_emprunts": false, "autoriser_dominantes_secondaires": false,
       "autoriser_mediantes_chromatiques": false, "random_seed": <graine>}
      """
    Alors la réponse a le statut 200
    Et aucun élément de "result.accords" n'a "est_emprunt" égal à true
    Et aucun élément de "result.accords" n'a "est_dominante_secondaire" égal à true
    Et aucun élément de "result.accords" n'a "est_mediante_chromatique" égal à true

    Exemples:
      | graine |
      | 1      |
      | 2      |
      | 3      |

  # réf: lyra-api/generation/GenerationController.java:53 ; lyra-ml/app/main.py:1017
  @AC-7 @api
  Plan du Scénario: Une dominante secondaire nomme sa cible tonicisée (graine <graine>)
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 110, "mode": "ionien", "tonique": "Do", "nombre_mesures": 16,
       "autoriser_dominantes_secondaires": true, "random_seed": <graine>}
      """
    Alors la réponse a le statut 200
    Et tout accord où "est_dominante_secondaire" vaut true a "cible_tonicisee" non vide
    # RISQUE : passe à vide si aucune dominante secondaire n'est tirée ; la suite de graines doit en produire au moins une
    Et au moins un accord de la progression pour cette graine est une dominante secondaire, ou la graine est signalée "sans objet"

    Exemples:
      | graine |
      | 1      |
      | 2      |
      | 3      |
      | 4      |
      | 5      |
      | 6      |

  # réf: lyra-api/generation/GenerationController.java:53 ; lyra-ml/app/main.py:1017
  @AC-6 @api
  Plan du Scénario: Un accord emprunté indique son mode source et une justification (graine <graine>)
    Quand j'envoie POST "/api/generate/chord-progression" avec le corps JSON :
      """
      {"tempo_bpm": 110, "mode": "ionien", "tonique": "Do", "nombre_mesures": 16,
       "autoriser_emprunts": true, "random_seed": <graine>}
      """
    Alors la réponse a le statut 200
    Et tout accord où "est_emprunt" vaut true a "mode_source" non vide
    Et tout accord où "est_emprunt" vaut true a "justification" non vide

    Exemples:
      | graine |
      | 1      |
      | 2      |
      | 3      |
      | 4      |
