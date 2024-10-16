-- Lines 15, 26 and 43

SELECT DISTINCT responsibility_id, responsibility_name
    FROM apps.fnd_responsibility_vl a
   WHERE     a.end_date IS NULL
         AND a.menu_id IN
                (    SELECT menu_id
                       FROM apps.fnd_menu_entries_vl
                 START WITH menu_id IN
                               (SELECT menu_id
                                  FROM apps.fnd_menu_entries_vl
                                 WHERE function_id IN
                                          (SELECT function_id
                                             FROM applsys.fnd_form_functions a
                                            WHERE 1=1
                                            and function_name = :pc_function_name
                                            --and function_id in (select function_id from  fnd_form_functions_tl where user_function_name like '%ENTRY%')
                                            ))
                 CONNECT BY PRIOR menu_id = sub_menu_id)
         AND a.responsibility_id NOT IN
                (SELECT responsibility_id
                   FROM apps.fnd_responsibility_vl
                  WHERE responsibility_id IN
                           (SELECT responsibility_id
                              FROM applsys.fnd_resp_functions resp
                             WHERE action_id IN
                                      (SELECT function_id
                                         FROM applsys.fnd_form_functions a
                                        WHERE 1=1
                                        and function_name = :pc_function_name)))
         AND a.responsibility_id NOT IN
                (SELECT responsibility_id
                   FROM apps.fnd_responsibility_vl
                  WHERE responsibility_id IN
                           (SELECT responsibility_id
                              FROM applsys.fnd_resp_functions resp
                             WHERE action_id IN
                                      (    SELECT menu_id
                                             FROM apps.fnd_menu_entries_vl
                                       START WITH menu_id IN
                                                     (SELECT menu_id
                                                        FROM apps.fnd_menu_entries_vl
                                                       WHERE function_id IN
                                                                (SELECT function_id
                                                                   FROM applsys.fnd_form_functions a
                                                                  WHERE 1=1
                                                                  and function_name = :pc_function_name
                                                                  ))
                                       CONNECT BY PRIOR menu_id = sub_menu_id)))

ORDER BY responsibility_id