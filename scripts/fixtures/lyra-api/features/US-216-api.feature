# language: fr
@US-216 @REQ-216 @api
Fonctionnalité: Mettre un texte en musique syllabe par syllabe (US-216)
  # REQ-216 - critères couverts à ce niveau : AC-4, AC-5, AC-6

  Contexte:
    Soit l'API Lyra joignable

  @AC-4 @api
  Scénario: Une mesure par vers, une note par syllabe, durées égales
    Quand j'envoie POST "/api/generate/mise-en-musique-syllabique" avec le corps JSON :
      """
      {"vers": ["un", "deux trois"], "accords": "@accords:I,V:4", "mode": "ionien", "tonique": "Do", "random_seed": 42}
      """
    Alors la réponse a le statut 200
    Et la liste "result.syllabes_par_vers" contient 2 éléments
    Et la liste "result.motif" a autant d'éléments que la somme de "result.syllabes_par_vers"

  @AC-5 @api
  Scénario: Même graine, même mélodie
    Quand j'envoie POST "/api/generate/mise-en-musique-syllabique" avec le corps JSON :
      """
      {"vers": ["un", "deux trois"], "accords": "@accords:I,V:4", "mode": "ionien", "tonique": "Do", "random_seed": 42}
      """
    Et j'envoie POST "/api/generate/mise-en-musique-syllabique" avec le corps JSON :
      """
      {"vers": ["un", "deux trois"], "accords": "@accords:I,V:4", "mode": "ionien", "tonique": "Do", "random_seed": 42}
      """
    Alors les "result.motif" des deux réponses sont identiques

  @AC-6 @api
  Scénario: Vers vide refusé
    Quand j'envoie POST "/api/generate/mise-en-musique-syllabique" avec le corps JSON :
      """
      {"vers": [""], "accords": "@accords:I:4", "mode": "ionien", "tonique": "Do"}
      """
    Alors la requête est refusée par une erreur 4xx

  # RÉSOLU (code) : « accords » doit couvrir exactement la grille (1 mesure de 4 temps par vers) : fixtures « @accords:I,V:4 » (durée 4, position_temps 1). La métrique asymétrique refusée est choisie parmi celles non supportées par le moteur (ici 5/8, à confirmer à l'exécution).
  @AC-6 @api
  Scénario: Métrique asymétrique refusée
    Quand j'envoie POST "/api/generate/mise-en-musique-syllabique" avec le corps JSON :
      """
      {"vers": ["un", "deux"], "accords": "@accords:I,V:4", "mode": "ionien", "tonique": "Do", "metrique": "5/8"}
      """
    Alors la requête est refusée par une erreur 4xx

  @AC-6 @api
  Scénario: Nombre d'accords différent du nombre de vers refusé
    Quand j'envoie POST "/api/generate/mise-en-musique-syllabique" avec le corps JSON :
      """
      {"vers": ["un", "deux"], "accords": "@accords:I,V,I:4", "mode": "ionien", "tonique": "Do"}
      """
    Alors la requête est refusée par une erreur 4xx
