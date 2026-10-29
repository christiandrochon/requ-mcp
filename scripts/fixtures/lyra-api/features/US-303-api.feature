# language: fr
@US-303 @REQ-303 @api
Fonctionnalité: Analyser la conduite des voix, le power chord assumé et le 6/4 légitime (US-303)
  # REQ-303 - critères couverts à ce niveau : AC-1, AC-2, AC-3
  # RÉSOLU (code) : la déclaration « power chord assumé » est le booléen tolerer_quintes_paralleles (ConduiteVoixArrangementRequest) : il s'applique aux pistes de guitare ; les paires non guitare restent signalées.

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api
  Scénario: Power chord assumé : quintes de la paire de guitares retirées, autre paire conservée
    Quand j'envoie POST "/api/arrange/conduite-voix-arrangement" avec le corps JSON :
      """
      {"tolerer_quintes_paralleles": true, "voix": [
        {"instrument": "guitare électrique (6 cordes)", "role": "harmonie/soutien", "justification": "f", "notes": "@notes:40,42,44,45,47"},
        {"instrument": "guitare électrique (6 cordes)", "role": "harmonie/soutien", "justification": "f", "notes": "@notes:47,49,51,52,54"},
        {"instrument": "violon", "role": "mélodie principale", "justification": "f", "notes": "@notes:60,62,64,65,67"},
        {"instrument": "violoncelle", "role": "basse", "justification": "f", "notes": "@notes:53,55,60,59,60"}]}
      """
    Alors la réponse a le statut 200
    Et la liste "violations" contient un élément dont "piste_a" vaut "violon"
    Et la liste "violations" ne contient pas la valeur "guitare"

  @AC-1 @api
  Scénario: Sans déclaration : relevé inchangé, quintes de guitare signalées
    Quand j'envoie POST "/api/arrange/conduite-voix-arrangement" avec le corps JSON :
      """
      {"tolerer_quintes_paralleles": false, "voix": [
        {"instrument": "guitare électrique (6 cordes)", "role": "harmonie/soutien", "justification": "f", "notes": "@notes:40,42,44,45,47"},
        {"instrument": "guitare électrique (6 cordes)", "role": "harmonie/soutien", "justification": "f", "notes": "@notes:47,49,51,52,54"}]}
      """
    Alors la réponse a le statut 200
    Et la liste "violations" n'est pas vide

  @AC-2 @api
  Scénario: Paires candidates power chord sur 3 transitions
    Quand j'envoie POST "/api/analyze/paires-power-chord-chorale" avec le corps JSON :
      """
      {"voix": [
        {"soprano": {"pitch": 72, "duree_temps": 1}, "alto": {"pitch": 67, "duree_temps": 1}, "tenor": {"pitch": 64, "duree_temps": 1}, "basse": {"pitch": 48, "duree_temps": 1}},
        {"soprano": {"pitch": 74, "duree_temps": 1}, "alto": {"pitch": 69, "duree_temps": 1}, "tenor": {"pitch": 64, "duree_temps": 1}, "basse": {"pitch": 50, "duree_temps": 1}},
        {"soprano": {"pitch": 76, "duree_temps": 1}, "alto": {"pitch": 71, "duree_temps": 1}, "tenor": {"pitch": 64, "duree_temps": 1}, "basse": {"pitch": 52, "duree_temps": 1}},
        {"soprano": {"pitch": 77, "duree_temps": 1}, "alto": {"pitch": 72, "duree_temps": 1}, "tenor": {"pitch": 64, "duree_temps": 1}, "basse": {"pitch": 53, "duree_temps": 1}}]}
      """
    Alors la réponse a le statut 200
    Et la liste "candidats" n'est pas vide

  @AC-2 @api
  Scénario: Chorale sans quinte parallèle répétée : aucun candidat
    Quand j'envoie POST "/api/analyze/paires-power-chord-chorale" avec le corps JSON :
      """
      {"voix": [
        {"soprano": {"pitch": 72, "duree_temps": 1}, "alto": {"pitch": 67, "duree_temps": 1}, "tenor": {"pitch": 64, "duree_temps": 1}, "basse": {"pitch": 48, "duree_temps": 1}},
        {"soprano": {"pitch": 71, "duree_temps": 1}, "alto": {"pitch": 67, "duree_temps": 1}, "tenor": {"pitch": 62, "duree_temps": 1}, "basse": {"pitch": 43, "duree_temps": 1}}]}
      """
    Alors la réponse a le statut 200
    Et la liste "candidats" est vide

  # RÉSOLU (code) : le 6/4 est classé par six-quatre : { basse_precedente, accord_courant, accord_suivant, basse_suivante } ; catégories à lire à l'exécution (orthographe non confirmée sans exécution).
  @AC-3 @api
  Scénario: Classification d'un 6/4 cadentiel I6/4 - V
    Quand j'envoie POST "/api/analyze/six-quatre" avec le corps JSON :
      """
      {"basse_precedente": "Fa", "accord_courant": "@accord:I", "accord_suivant": "@accord:V", "basse_suivante": "Sol"}
      """
    Alors la réponse a le statut 200
    Et le champ "categorie" est non vide
