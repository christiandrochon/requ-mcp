# language: fr
@api @US-123 @REQ-123
Fonctionnalité: Arrangement multi-instruments par rôle et courbe de tension, sans limite de voix

  Contexte:
    Soit l'API Lyra joignable

  # réf: lyra-api/analysis/AnalysisController.java:631 ; lyra-ml/app/main.py:4985 ; arrangement.py:612-628 (informatif, ADR 0008)
  @AC-3 @api
  Scénario: Un déséquilibre produit une information, jamais un refus
    Quand j'envoie POST "/api/analyze/equilibre-orchestral" avec le corps JSON :
      """
      {"instruments": ["trompette (si♭)", "trompette (si♭)", "trompette (si♭)", "trombone ténor", "tuba", "flûte"]}
      """
    Alors la réponse a le statut 200
    Et le champ "trompette (si♭)" vaut 12
    # A CONFIRMER : la « recommandation » se réduit à des totaux d'unités de force par instrument (aucun libellé de recommandation dans la réponse) ; texte attendu à trancher avec le PO
    Et la réponse ne contient aucune erreur

  # réf: lyra-api/generation/ArrangementController.java:97 ; lyra-ml/app/main.py:1654 ; arrangement.py:1377-1383, 1777-1853
  @AC-4 @api
  Scénario: Chaque section a un porteur de « mélodie principale » et tous les rôles sont dans la taxonomie
    Quand j'envoie POST "/api/arrange/orchestration-par-tension" avec le corps JSON :
      """
      {"sections": [[{"pitch":60,"duree_temps":1},{"pitch":62,"duree_temps":1}],
                    [{"pitch":64,"duree_temps":1},{"pitch":65,"duree_temps":1}],
                    [{"pitch":67,"duree_temps":1},{"pitch":69,"duree_temps":1}]],
       "instruments_disponibles": ["flûte", "hautbois", "violon", "violoncelle", "cor (fa)", "contrebasse"],
       "indice_climax": 2, "force_minimale": 1.0, "force_climax": 5.0}
      """
    Alors la réponse a le statut 200
    Et pour chaque "indice_section" de 0 à 2, un élément de "assignations" a "role" égal à "mélodie principale"
    Et chaque "role" de "assignations" appartient à ["mélodie principale", "contre-chant/doublage", "harmonie/soutien", "basse", "pédale", "couleur/texture"]

  # réf: lyra-api/generation/ArrangementController.java:97 ; lyra-ml/app/main.py:1654
  @AC-5 @api
  Scénario: Plusieurs pistes du même instrument sont acceptées sans erreur de limite
    Quand j'envoie POST "/api/arrange/orchestration-par-tension" avec 12 fois "violon" dans "instruments_disponibles" et 2 sections
    # A CONFIRMER : l'API accepte-t-elle des doublons de nom (List<String>), et « pistes du même instrument » désigne-t-il plutôt plusieurs parties d'une partition Composer (piste = track) ? Cible alternative : PieceController
    Alors la réponse a le statut 200
    Et la réponse ne contient aucune erreur de limite de voix ou de pistes
