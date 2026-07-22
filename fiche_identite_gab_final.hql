-- ==============================================================================
-- FICHE IDENTITÉ GAB — 1 SEULE RECIPE HIVE
-- INPUT  1 : tableretrait
-- INPUT  2 : table_ref_gab
-- OUTPUT   : fiche_identite_gab_mensuel
-- ==============================================================================
-- NOTES IMPORTANTES :
--   - date_operation  : STRING format DDMMYYYY ex: '02022026'
--                       → jour  = SUBSTR(date_operation,1,2)
--                       → mois  = SUBSTR(date_operation,3,2)
--                       → annee = SUBSTR(date_operation,5,4)
--   - heure_operation : STRING format HHMMSS ex: '155735'
--                       → heure = CAST(SUBSTR(LPAD(heure_operation,6,'0'),1,2) AS INT)
--   - montant_ope     : STRING → CAST en DOUBLE
--   - lib_ope valeurs exactes :
--                       'Retrait'               → type RETRAIT
--                       'Autorisation-Retrait'  → type RETRAIT
--                       'Capture de Carte'      → type CAPTURE
--   - type-gab_e_i    : nom avec tiret → entouré de backticks
--   - type_reseau     : CASE confidentiel à insérer à l'emplacement marqué
--                       → produit une colonne cat_reseau
--                       → agrégats nb_ope + montant par catégorie réseau
-- ==============================================================================
-- COLONNES À DÉCLARER DANS DATAIKU POUR fiche_identite_gab_mensuel :
--
--   num_automate STRING, annee INT, mois INT,
--   code_entite_de_gestion STRING, type_gab_e_i STRING,
--   code_postale_emplacement STRING, longitude DOUBLE, latitude DOUBLE,
--   ret_nb BIGINT, ret_nb_jours_actifs BIGINT,
--   ret_montant_total DOUBLE, ret_montant_moyen DOUBLE,
--   ret_montant_max DOUBLE, ret_montant_min DOUBLE, ret_montant_stddev DOUBLE,
--   ret_nb_nuit BIGINT, ret_nb_weekend BIGINT, ret_nb_heure_pointe BIGINT,
--   ret_heure_moyenne DOUBLE, ret_pct_nuit DOUBLE, ret_pct_weekend DOUBLE,
--   cap_nb BIGINT, cap_nb_nuit BIGINT, cap_nb_weekend BIGINT,
--   cap_heure_moyenne DOUBLE, taux_capture_pct DOUBLE,
--   nb_ope_reseau_CAT1 BIGINT, montant_reseau_CAT1 DOUBLE,
--   nb_ope_reseau_CAT2 BIGINT, montant_reseau_CAT2 DOUBLE,
--   nb_ope_reseau_CAT3 BIGINT, montant_reseau_CAT3 DOUBLE,
--   nb_ope_reseau_CAT4 BIGINT, montant_reseau_CAT4 DOUBLE,
--   nb_ope_reseau_autres BIGINT, montant_reseau_autres DOUBLE,
--   zscore_ret_nb DOUBLE, zscore_ret_montant_total DOUBLE,
--   zscore_ret_montant_moyen DOUBLE, zscore_ret_nb_nuit DOUBLE,
--   zscore_pct_nuit DOUBLE, zscore_ret_nb_weekend DOUBLE,
--   zscore_cap_nb DOUBLE, zscore_taux_capture DOUBLE,
--   nb_metriques_anormales INT, flag_atypique INT
-- ==============================================================================

SELECT

    -- ── CLÉS ─────────────────────────────────────────────────────────────────
    gab_mois.num_automate,
    gab_mois.annee,
    gab_mois.mois,

    -- ── RÉFÉRENTIEL GAB ──────────────────────────────────────────────────────
    g.code_entite_de_gestion,
    g.`type-gab_e_i`                                        AS type_gab_e_i,
    g.code_postale_emplacement,
    g.longitude,
    g.latitude,

    -- ── STATS RETRAITS ───────────────────────────────────────────────────────
    gab_mois.ret_nb,
    gab_mois.ret_nb_jours_actifs,
    gab_mois.ret_montant_total,
    gab_mois.ret_montant_moyen,
    gab_mois.ret_montant_max,
    gab_mois.ret_montant_min,
    gab_mois.ret_montant_stddev,
    gab_mois.ret_nb_nuit,
    gab_mois.ret_nb_weekend,
    gab_mois.ret_nb_heure_pointe,
    gab_mois.ret_heure_moyenne,
    gab_mois.ret_pct_nuit,
    gab_mois.ret_pct_weekend,

    -- ── STATS CAPTURES ───────────────────────────────────────────────────────
    gab_mois.cap_nb,
    gab_mois.cap_nb_nuit,
    gab_mois.cap_nb_weekend,
    gab_mois.cap_heure_moyenne,
    gab_mois.taux_capture_pct,

    -- ── AGRÉGATS PAR CATÉGORIE RÉSEAU ────────────────────────────────────────
    -- Remplacer CAT1, CAT2, CAT3, CAT4 par vos vraies valeurs de cat_reseau
    gab_mois.nb_ope_reseau_CAT1,
    gab_mois.montant_reseau_CAT1,
    gab_mois.nb_ope_reseau_CAT2,
    gab_mois.montant_reseau_CAT2,
    gab_mois.nb_ope_reseau_CAT3,
    gab_mois.montant_reseau_CAT3,
    gab_mois.nb_ope_reseau_CAT4,
    gab_mois.montant_reseau_CAT4,
    gab_mois.nb_ope_reseau_autres,
    gab_mois.montant_reseau_autres,

    -- ── Z-SCORES ─────────────────────────────────────────────────────────────
    ROUND((gab_mois.ret_nb            - per.avg_ret_nb)
        / NULLIF(per.std_ret_nb, 0), 4)                     AS zscore_ret_nb,

    ROUND((gab_mois.ret_montant_total - per.avg_ret_montant_total)
        / NULLIF(per.std_ret_montant_total, 0), 4)          AS zscore_ret_montant_total,

    ROUND((gab_mois.ret_montant_moyen - per.avg_ret_montant_moyen)
        / NULLIF(per.std_ret_montant_moyen, 0), 4)          AS zscore_ret_montant_moyen,

    ROUND((gab_mois.ret_nb_nuit       - per.avg_ret_nb_nuit)
        / NULLIF(per.std_ret_nb_nuit, 0), 4)                AS zscore_ret_nb_nuit,

    ROUND((gab_mois.ret_pct_nuit      - per.avg_ret_pct_nuit)
        / NULLIF(per.std_ret_pct_nuit, 0), 4)               AS zscore_pct_nuit,

    ROUND((gab_mois.ret_nb_weekend    - per.avg_ret_nb_weekend)
        / NULLIF(per.std_ret_nb_weekend, 0), 4)             AS zscore_ret_nb_weekend,

    ROUND((gab_mois.cap_nb            - per.avg_cap_nb)
        / NULLIF(per.std_cap_nb, 0), 4)                     AS zscore_cap_nb,

    ROUND((gab_mois.taux_capture_pct  - per.avg_taux_capture)
        / NULLIF(per.std_taux_capture, 0), 4)               AS zscore_taux_capture,

    -- ── SCORE ANOMALIE GLOBAL ─────────────────────────────────────────────────
    (
        CASE WHEN ABS((gab_mois.ret_nb            - per.avg_ret_nb)            / NULLIF(per.std_ret_nb,            0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.ret_montant_total - per.avg_ret_montant_total) / NULLIF(per.std_ret_montant_total, 0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.ret_montant_moyen - per.avg_ret_montant_moyen) / NULLIF(per.std_ret_montant_moyen, 0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.ret_nb_nuit       - per.avg_ret_nb_nuit)       / NULLIF(per.std_ret_nb_nuit,       0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.ret_pct_nuit      - per.avg_ret_pct_nuit)      / NULLIF(per.std_ret_pct_nuit,      0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.ret_nb_weekend    - per.avg_ret_nb_weekend)    / NULLIF(per.std_ret_nb_weekend,    0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.cap_nb            - per.avg_cap_nb)            / NULLIF(per.std_cap_nb,            0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.taux_capture_pct  - per.avg_taux_capture)      / NULLIF(per.std_taux_capture,      0)) > 2 THEN 1 ELSE 0 END
    )                                                       AS nb_metriques_anormales,

    CASE WHEN (
        CASE WHEN ABS((gab_mois.ret_nb            - per.avg_ret_nb)            / NULLIF(per.std_ret_nb,            0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.ret_montant_total - per.avg_ret_montant_total) / NULLIF(per.std_ret_montant_total, 0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.ret_montant_moyen - per.avg_ret_montant_moyen) / NULLIF(per.std_ret_montant_moyen, 0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.ret_nb_nuit       - per.avg_ret_nb_nuit)       / NULLIF(per.std_ret_nb_nuit,       0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.ret_pct_nuit      - per.avg_ret_pct_nuit)      / NULLIF(per.std_ret_pct_nuit,      0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.ret_nb_weekend    - per.avg_ret_nb_weekend)    / NULLIF(per.std_ret_nb_weekend,    0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.cap_nb            - per.avg_cap_nb)            / NULLIF(per.std_cap_nb,            0)) > 2 THEN 1 ELSE 0 END +
        CASE WHEN ABS((gab_mois.taux_capture_pct  - per.avg_taux_capture)      / NULLIF(per.std_taux_capture,      0)) > 2 THEN 1 ELSE 0 END
    ) >= 2 THEN 1 ELSE 0 END                                AS flag_atypique


FROM (
    -- ══════════════════════════════════════════════════════════════════════════
    -- SOUS-REQUÊTE A : agrégats par GAB + mois
    -- ══════════════════════════════════════════════════════════════════════════
    SELECT
        num_automate,
        annee,
        mois,

        -- Stats retraits (RETRAIT + AUTORISATION-RETRAIT regroupés)
        SUM(CASE WHEN type_op = 'RETRAIT' THEN 1 ELSE 0 END)                AS ret_nb,
        COUNT(DISTINCT CASE WHEN type_op = 'RETRAIT' THEN date_iso END)     AS ret_nb_jours_actifs,
        SUM(CASE WHEN type_op = 'RETRAIT' THEN montant ELSE 0 END)          AS ret_montant_total,
        AVG(CASE WHEN type_op = 'RETRAIT' THEN montant ELSE NULL END)       AS ret_montant_moyen,
        MAX(CASE WHEN type_op = 'RETRAIT' THEN montant ELSE NULL END)       AS ret_montant_max,
        MIN(CASE WHEN type_op = 'RETRAIT' THEN montant ELSE NULL END)       AS ret_montant_min,
        STDDEV_POP(CASE WHEN type_op = 'RETRAIT' THEN montant ELSE NULL END) AS ret_montant_stddev,
        SUM(CASE WHEN type_op = 'RETRAIT' THEN is_nuit    ELSE 0 END)       AS ret_nb_nuit,
        SUM(CASE WHEN type_op = 'RETRAIT' THEN is_weekend ELSE 0 END)       AS ret_nb_weekend,
        SUM(CASE WHEN type_op = 'RETRAIT' THEN is_hpointe ELSE 0 END)       AS ret_nb_heure_pointe,
        AVG(CASE WHEN type_op = 'RETRAIT' THEN heure      ELSE NULL END)    AS ret_heure_moyenne,
        ROUND(
            SUM(CASE WHEN type_op = 'RETRAIT' THEN is_nuit ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN type_op = 'RETRAIT' THEN 1 ELSE 0 END), 0)
        , 2)                                                                 AS ret_pct_nuit,
        ROUND(
            SUM(CASE WHEN type_op = 'RETRAIT' THEN is_weekend ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN type_op = 'RETRAIT' THEN 1 ELSE 0 END), 0)
        , 2)                                                                 AS ret_pct_weekend,

        -- Stats captures
        SUM(CASE WHEN type_op = 'CAPTURE' THEN 1 ELSE 0 END)               AS cap_nb,
        SUM(CASE WHEN type_op = 'CAPTURE' THEN is_nuit    ELSE 0 END)       AS cap_nb_nuit,
        SUM(CASE WHEN type_op = 'CAPTURE' THEN is_weekend ELSE 0 END)       AS cap_nb_weekend,
        AVG(CASE WHEN type_op = 'CAPTURE' THEN heure      ELSE NULL END)    AS cap_heure_moyenne,
        ROUND(
            SUM(CASE WHEN type_op = 'CAPTURE' THEN 1 ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN type_op = 'RETRAIT' THEN 1 ELSE 0 END), 0)
        , 4)                                                                 AS taux_capture_pct,

        -- ── AGRÉGATS PAR CATÉGORIE RÉSEAU ─────────────────────────────────
        -- Remplacer 'CAT1' 'CAT2' 'CAT3' 'CAT4' par vos vraies valeurs
        -- issues de votre CASE sur type_reseau
        SUM(CASE WHEN cat_reseau = 'CAT1' THEN 1       ELSE 0 END)         AS nb_ope_reseau_CAT1,
        SUM(CASE WHEN cat_reseau = 'CAT1' THEN montant ELSE 0 END)         AS montant_reseau_CAT1,
        SUM(CASE WHEN cat_reseau = 'CAT2' THEN 1       ELSE 0 END)         AS nb_ope_reseau_CAT2,
        SUM(CASE WHEN cat_reseau = 'CAT2' THEN montant ELSE 0 END)         AS montant_reseau_CAT2,
        SUM(CASE WHEN cat_reseau = 'CAT3' THEN 1       ELSE 0 END)         AS nb_ope_reseau_CAT3,
        SUM(CASE WHEN cat_reseau = 'CAT3' THEN montant ELSE 0 END)         AS montant_reseau_CAT3,
        SUM(CASE WHEN cat_reseau = 'CAT4' THEN 1       ELSE 0 END)         AS nb_ope_reseau_CAT4,
        SUM(CASE WHEN cat_reseau = 'CAT4' THEN montant ELSE 0 END)         AS montant_reseau_CAT4,
        SUM(CASE WHEN cat_reseau NOT IN ('CAT1','CAT2','CAT3','CAT4')
                  OR cat_reseau IS NULL THEN 1       ELSE 0 END)            AS nb_ope_reseau_autres,
        SUM(CASE WHEN cat_reseau NOT IN ('CAT1','CAT2','CAT3','CAT4')
                  OR cat_reseau IS NULL THEN montant ELSE 0 END)            AS montant_reseau_autres

    FROM (
        -- ════════════════════════════════════════════════════════════════════
        -- SOUS-REQUÊTE A1 : parsing + flags + classification
        -- ════════════════════════════════════════════════════════════════════
        SELECT
            num_automate,

            -- Date : STRING DDMMYYYY → reconstruction ISO pour DAYOFWEEK
            CONCAT(
                SUBSTR(date_operation, 5, 4), '-',   -- YYYY
                SUBSTR(date_operation, 3, 2), '-',   -- MM
                SUBSTR(date_operation, 1, 2)          -- DD
            )                                                               AS date_iso,

            -- Annee et mois castés en INT pour les GROUP BY
            CAST(SUBSTR(date_operation, 5, 4) AS INT)                       AS annee,
            CAST(SUBSTR(date_operation, 3, 2) AS INT)                       AS mois,

            -- Heure : LPAD sécurise si heure < 6 chiffres (ex: '90000' → '090000')
            CAST(SUBSTR(LPAD(heure_operation, 6, '0'), 1, 2) AS INT)        AS heure,

            -- Montant : STRING → DOUBLE, remplacement virgule si nécessaire
            CAST(REGEXP_REPLACE(montant_ope, ',', '.') AS DOUBLE)           AS montant,

            -- Classification opération
            CASE
                WHEN lib_ope = 'Retrait'               THEN 'RETRAIT'
                WHEN lib_ope = 'Autorisation-Retrait'  THEN 'RETRAIT'
                WHEN lib_ope = 'Capture de Carte'      THEN 'CAPTURE'
            END                                                             AS type_op,

            -- Flag nuit : 22h00 → 05h59
            CASE
                WHEN CAST(SUBSTR(LPAD(heure_operation, 6, '0'), 1, 2) AS INT) >= 22
                  OR CAST(SUBSTR(LPAD(heure_operation, 6, '0'), 1, 2) AS INT) <   6
                THEN 1 ELSE 0
            END                                                             AS is_nuit,

            -- Flag weekend : DAYOFWEEK 1=dimanche, 7=samedi
            CASE
                WHEN DAYOFWEEK(CONCAT(
                    SUBSTR(date_operation, 5, 4), '-',
                    SUBSTR(date_operation, 3, 2), '-',
                    SUBSTR(date_operation, 1, 2)
                )) IN (1, 7)
                THEN 1 ELSE 0
            END                                                             AS is_weekend,

            -- Flag heure de pointe : 8-9h / 12-13h / 17-18h
            CASE
                WHEN CAST(SUBSTR(LPAD(heure_operation, 6, '0'), 1, 2) AS INT) BETWEEN  8 AND  9
                  OR CAST(SUBSTR(LPAD(heure_operation, 6, '0'), 1, 2) AS INT) BETWEEN 12 AND 13
                  OR CAST(SUBSTR(LPAD(heure_operation, 6, '0'), 1, 2) AS INT) BETWEEN 17 AND 18
                THEN 1 ELSE 0
            END                                                             AS is_hpointe,

            -- ── VOTRE CASE TYPE_RESEAU À INSÉRER ICI ─────────────────────
            -- Remplacer le bloc ci-dessous par votre CASE confidentiel
            -- Le résultat doit s'appeler cat_reseau
            -- Exemple de structure attendue :
            --
            -- CASE
            --     WHEN type_reseau = '...' THEN 'CAT1'
            --     WHEN type_reseau = '...' THEN 'CAT2'
            --     WHEN type_reseau IN ('...','...') THEN 'CAT3'
            --     WHEN type_reseau = '...' THEN 'CAT4'
            --     ELSE 'autres'
            -- END AS cat_reseau
            --
            -- ↓↓↓ REMPLACER LA LIGNE SUIVANTE PAR VOTRE CASE ↓↓↓
            CAST(NULL AS STRING)                                            AS cat_reseau
            -- ↑↑↑ REMPLACER LA LIGNE CI-DESSUS PAR VOTRE CASE ↑↑↑

        FROM tableretrait
        WHERE lib_ope IN ('Retrait', 'Autorisation-Retrait', 'Capture de Carte')

    ) ops_enrichies
    GROUP BY num_automate, annee, mois

) gab_mois

-- ══════════════════════════════════════════════════════════════════════════════
-- SOUS-REQUÊTE B : moyennes + écarts-types cross-GAB par période (annee+mois)
-- Remplace les fonctions fenêtres OVER(PARTITION BY) non supportées
-- ══════════════════════════════════════════════════════════════════════════════
LEFT JOIN (
    SELECT
        annee,
        mois,
        AVG(ret_nb)                     AS avg_ret_nb,
        STDDEV_POP(ret_nb)              AS std_ret_nb,
        AVG(ret_montant_total)          AS avg_ret_montant_total,
        STDDEV_POP(ret_montant_total)   AS std_ret_montant_total,
        AVG(ret_montant_moyen)          AS avg_ret_montant_moyen,
        STDDEV_POP(ret_montant_moyen)   AS std_ret_montant_moyen,
        AVG(ret_nb_nuit)                AS avg_ret_nb_nuit,
        STDDEV_POP(ret_nb_nuit)         AS std_ret_nb_nuit,
        AVG(ret_pct_nuit)               AS avg_ret_pct_nuit,
        STDDEV_POP(ret_pct_nuit)        AS std_ret_pct_nuit,
        AVG(ret_nb_weekend)             AS avg_ret_nb_weekend,
        STDDEV_POP(ret_nb_weekend)      AS std_ret_nb_weekend,
        AVG(cap_nb)                     AS avg_cap_nb,
        STDDEV_POP(cap_nb)              AS std_cap_nb,
        AVG(taux_capture_pct)           AS avg_taux_capture,
        STDDEV_POP(taux_capture_pct)    AS std_taux_capture
    FROM (
        -- Même agrégat GAB/mois recalculé pour avoir les stats de période
        SELECT
            num_automate,
            CAST(SUBSTR(date_operation, 5, 4) AS INT)                       AS annee,
            CAST(SUBSTR(date_operation, 3, 2) AS INT)                       AS mois,
            SUM(CASE WHEN lib_ope IN ('Retrait','Autorisation-Retrait')
                     THEN 1 ELSE 0 END)                                     AS ret_nb,
            SUM(CASE WHEN lib_ope IN ('Retrait','Autorisation-Retrait')
                     THEN CAST(REGEXP_REPLACE(montant_ope,',','.') AS DOUBLE)
                     ELSE 0 END)                                            AS ret_montant_total,
            AVG(CASE WHEN lib_ope IN ('Retrait','Autorisation-Retrait')
                     THEN CAST(REGEXP_REPLACE(montant_ope,',','.') AS DOUBLE)
                     ELSE NULL END)                                         AS ret_montant_moyen,
            SUM(CASE WHEN lib_ope IN ('Retrait','Autorisation-Retrait')
                      AND (CAST(SUBSTR(LPAD(heure_operation,6,'0'),1,2) AS INT) >= 22
                        OR CAST(SUBSTR(LPAD(heure_operation,6,'0'),1,2) AS INT) <   6)
                     THEN 1 ELSE 0 END)                                     AS ret_nb_nuit,
            ROUND(
                SUM(CASE WHEN lib_ope IN ('Retrait','Autorisation-Retrait')
                          AND (CAST(SUBSTR(LPAD(heure_operation,6,'0'),1,2) AS INT) >= 22
                            OR CAST(SUBSTR(LPAD(heure_operation,6,'0'),1,2) AS INT) <   6)
                         THEN 1 ELSE 0 END) * 100.0
                / NULLIF(SUM(CASE WHEN lib_ope IN ('Retrait','Autorisation-Retrait')
                                  THEN 1 ELSE 0 END), 0)
            , 2)                                                            AS ret_pct_nuit,
            SUM(CASE WHEN lib_ope IN ('Retrait','Autorisation-Retrait')
                      AND DAYOFWEEK(CONCAT(
                            SUBSTR(date_operation,5,4),'-',
                            SUBSTR(date_operation,3,2),'-',
                            SUBSTR(date_operation,1,2))) IN (1,7)
                     THEN 1 ELSE 0 END)                                     AS ret_nb_weekend,
            SUM(CASE WHEN lib_ope = 'Capture de Carte'
                     THEN 1 ELSE 0 END)                                     AS cap_nb,
            ROUND(
                SUM(CASE WHEN lib_ope = 'Capture de Carte' THEN 1 ELSE 0 END) * 100.0
                / NULLIF(SUM(CASE WHEN lib_ope IN ('Retrait','Autorisation-Retrait')
                                  THEN 1 ELSE 0 END), 0)
            , 4)                                                            AS taux_capture_pct
        FROM tableretrait
        WHERE lib_ope IN ('Retrait', 'Autorisation-Retrait', 'Capture de Carte')
        GROUP BY
            num_automate,
            CAST(SUBSTR(date_operation, 5, 4) AS INT),
            CAST(SUBSTR(date_operation, 3, 2) AS INT)
    ) agg_pour_stats
    GROUP BY annee, mois
) per
    ON  gab_mois.annee = per.annee
    AND gab_mois.mois  = per.mois

-- ══════════════════════════════════════════════════════════════════════════════
-- JOINTURE RÉFÉRENTIEL GAB
-- ══════════════════════════════════════════════════════════════════════════════
LEFT JOIN table_ref_gab g
    ON gab_mois.num_automate = g.num_automate

;
