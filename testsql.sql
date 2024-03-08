  PROCEDURE MRUPDMBAT01_Validate1(pc_crt_user IN VARCHAR2,
                                  pc_crt_date IN DATE,
								  pc_TPA_Ind IN CHAR,    --2017-11-15 Teddy Chiu REF-2671 CR380 Phase 2
                                  pn_status OUT NUMBER,
                                  pv_errmsg OUT VARCHAR2) IS
-- 2006-10-13 END
  lc_err MR_MBR_BAT_UPD.err_code%TYPE;
  lc_prev_cont_no VARCHAR2(10);
  lc_prev_mbr_type VARCHAR2(10);
  lc_InvalidFamily CHAR(1);
  li_ForwardDate INTEGER;
  li_BackDate INTEGER;

  ld_BatchRunDate DATE;
  li_BDayLimit INTEGER;
  li_Overage INTEGER;
  li_MaxAge INTEGER; --2009-07-21 CR076 REF-0608 HoLaamC
  ls_return_value CHAR(3);
  lc_MdyTitle CHAR(1);
  lc_tmp_yymm_new MR_CONTRACT.CONT_YYMM%TYPE;
  ln_check number;

  lv_valid_line VARCHAR2(10);
 lv_iban MR_MBR_BAT_UPD.iban%TYPE;    --REF0625 WilliamW 16/10/2009
  BEGIN
    pn_status := 0;
     pv_errmsg := ' ';
     lc_err := LPAD(lc_err, 120, '0');
  --li_ForwardDate := 6;
  --li_BackDate := 15;
  li_BDayLimit := 14;
  li_Overage := 65;
  li_MaxAge := 100; --2009-07-21 CR076 REF-0608 HoLaamC

  SELECT num_value into li_BackDate
  FROM SY_SYS_PARAM
  WHERE sys_param = 'MAX_BACKDATE_MTH';

  SELECT num_value into li_ForwardDate
  FROM SY_SYS_PARAM
  WHERE sys_param = 'MAX_FORWARDDATE_MTH';
  
  --2018-03-02 REF-2773 Prod Log JimmyC Start
  --set to too large to let it pass the validation when it is TPA
  IF pc_TPA_Ind = 'Y' THEN
     li_ForwardDate := 999;
  END IF;
  --2018-03-02 REF-2773 Prod Log JimmyC End

  ls_return_value :=CSR.GL_LIB_PKG.GET_REGPARAM_VALUE( 'MR', 'SP', 'MBRNO_STRUCTURE' );
  lc_MdyTitle :=CSR.GL_LIB_PKG.GET_REGPARAM_VALUE( 'SCREEN', 'MRMEMBMNT01.MANDATORY_COLOR', 'Cbo_Title' );

     IF UPPER(ls_return_value)='BME' THEN
         SELECT SYSDATE INTO ld_BatchRunDate FROM DUAL;
     ELSE
         SELECT NVL(date_value, SYSDATE) INTO ld_BatchRunDate
      FROM SY_SYS_PARAM
      WHERE sys_param = 'CUR_BATCH_RUN_DATE';
     END IF;

  --update mr_mbr_bat_crt
  --set data_type = '1',
  --    err_code = '000000000000000000000000000000';

ln_check := -800;
  ------------------------------
     --1. Adjustment Code
  --   1.1 Missing value
  UPDATE MR_MBR_BAT_UPD
  SET err_code = '1' || SUBSTR(err_code, 2)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   (trim(adj_code) = '' OR adj_code IS NULL)
  AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
  AND CRT_DATE=pc_crt_date;               -- 2006-10-13
--    --   1.2 Check valid Adj Code
  IF UPPER(ls_return_value)='BHK' THEN
         UPDATE MR_MBR_BAT_UPD
         SET err_code = '2' || SUBSTR(err_code, 2)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND not adj_code in ('000','201','301','401','501','601','701','801','901')
         AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
         AND CRT_DATE=pc_crt_date;               -- 2006-10-13
     ELSE

      UPDATE MR_MBR_BAT_UPD
         SET err_code = '2' || SUBSTR(err_code, 2)
         WHERE SUBSTR(err_code, 1, 1) = '0'
-- 2006-10-13 START
--         AND not adj_code in ('000','401','601','701','801');
         --AND not adj_code in ('000','401','601','701', '702', '703', '801') --2013-03-12 REF-1206 CR137 RichardL
         AND not adj_code in ('000','350','401','601','701', '702', '703', '801') --2013-03-12 REF-1206 CR137 RichardL
         AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
         AND CRT_DATE=pc_crt_date;               -- 2006-10-13
-- 2006-10-13 END
  END IF;
--   IF UPPER(ls_return_value)='BHK' THEN
--          UPDATE MR_MBR_BAT_UPD
--          SET err_code = '2' || SUBSTR(err_code, 2)
--          WHERE SUBSTR(err_code, 1, 1) = '0'
--        AND NOT EXISTS (SELECT 1 FROM SY_SYS_CODE
--                   WHERE SY_SYS_CODE.SYS_TYPE='ADJ_CODE'
--                 AND SY_SYS_CODE.FLAG='U'
--              AND trim(SY_SYS_CODE.SYS_CODE)=MR_MBR_BAT_UPD.ADJ_CODE);
-- --         AND not adj_code in ('000','201','301','401','501','601','701','801','901');
--      ELSE

--       UPDATE MR_MBR_BAT_UPD
--          SET err_code = '2' || SUBSTR(err_code, 2)
--          WHERE SUBSTR(err_code, 1, 1) = '0'
--        AND NOT EXISTS (SELECT 1 FROM SY_SYS_CODE
--                   WHERE SY_SYS_CODE.SYS_TYPE='ADJ_CODE'
--                 AND SY_SYS_CODE.FLAG='U'
--              AND trim(SY_SYS_CODE.SYS_CODE)=MR_MBR_BAT_UPD.ADJ_CODE);

--   END IF;
  --1.3 Too long
  UPDATE MR_MBR_BAT_UPD
  SET err_code = '9' || SUBSTR(err_code, 2)
  WHERE length(trim(adj_code))>3
  AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
  AND CRT_DATE=pc_crt_date;               -- 2006-10-13

  lv_valid_line := TRIM('1 OK');



ln_check := -810;
  ------------------------------
     --2. Contract No.
  --   2.1 Missing value
  IF UPPER(ls_return_value)='BHK' then
     UPDATE MR_MBR_BAT_UPD
        SET err_code = SUBSTR(err_code, 1, 1) || '1' || SUBSTR(err_code, 3)
        WHERE SUBSTR(err_code, 1, 1) = '0'
        AND   SUBSTR(err_code, 2, 1) = '0'
        AND   (trim(cont_no) = '' OR cont_no IS NULL)
        AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
        AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --   2.2 Does not exist
     UPDATE MR_MBR_BAT_UPD
        SET err_code = SUBSTR(err_code, 1, 1) || '2' || SUBSTR(err_code, 3)
        WHERE SUBSTR(err_code, 1, 1) = '0'
        AND   SUBSTR(err_code, 2, 1) = '0'
        AND   NOT cont_no IS NULL
        AND   NOT cont_no IN (SELECT cont_no FROM MR_CUSTOMER_TBL)
        AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
        AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --   2.3 Check Group Product
     UPDATE MR_MBR_BAT_UPD
        SET err_code = SUBSTR(err_code, 1, 1) || '3' || SUBSTR(err_code, 3)
        WHERE SUBSTR(err_code, 1, 1) = '0'
        AND   SUBSTR(err_code, 2, 1) = '0'
        AND   NOT cont_no IS NULL
        AND   not Exists (SELECT cont_no FROM MR_Contract
                             where cont_no = MR_MBR_BAT_UPD.cont_no
                             and   substr(prod_type,1,1) = 'G')
        AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
        AND CRT_DATE=pc_crt_date;               -- 2006-10-13

  --2.4 Too long
     UPDATE MR_MBR_BAT_UPD
        SET err_code = SUBSTR(err_code, 1, 1) || '9' || SUBSTR(err_code, 3)
        WHERE SUBSTR(err_code, 1, 1) = '0'
        AND length(trim(cont_no))>8
        AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
        AND CRT_DATE=pc_crt_date;               -- 2006-10-13
  END IF;

  lv_valid_line := TRIM('2 OK');
    ------------------------------
ln_check := -820;
  IF upper(ls_return_value)='BHK' THEN
      --3. Member No.
  --   3.1 Missing value
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 2) || '1' || SUBSTR(err_code, 4)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND   SUBSTR(err_code, 2, 1) = '0'
         AND   SUBSTR(err_code, 3, 1) = '0'
         AND   (trim(mbr_no) = '' OR mbr_no IS NULL)
         AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
         AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --   3.2 Does not exist if N stands for BHK otherswise stands for BME, Author:Tommy,Date:20040422
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 2) || '2' || SUBSTR(err_code, 4)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND   SUBSTR(err_code, 2, 1) = '0'
         AND   SUBSTR(err_code, 3, 1) = '0'
         AND   Not Exists (SELECT 1 FROM mr_member
                              WHERE cont_no = MR_MBR_BAT_UPD.cont_no
                              AND   mbr_no = MR_MBR_BAT_UPD.mbr_no)
         AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
         AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --3.4 Too long
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 2) || '9' || SUBSTR(err_code, 4)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND length(trim(mbr_no))>8
         AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
         AND CRT_DATE=pc_crt_date;               -- 2006-10-13

  ELSIF upper(ls_return_value)='BME' THEN


  --   2.2  membership number was apparently not for the customer number
     UPDATE MR_MBR_BAT_UPD
        SET err_code = SUBSTR(err_code, 1, 1) || '4' || SUBSTR(err_code, 3)
        WHERE SUBSTR(err_code, 1, 1) = '0'
        AND   SUBSTR(err_code, 2, 1) = '0'
        AND   NOT cont_no IS NULL
        AND   NOT MBRSHP_NO IS NULL
        AND   not EXISTS (SELECT 1 FROM MR_MEMBER WHERE MR_MEMBER.CONT_NO = MR_MBR_BAT_UPD.CONT_NO
                                          AND MR_MEMBER.MBRSHP_NO = MR_MBR_BAT_UPD.MBRSHP_NO)
        AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
        AND   CRT_DATE=pc_crt_date;               -- 2006-10-13


  --3. Member No.
  --   3.1 Missing value
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 2) || '1' || SUBSTR(err_code, 4)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND   SUBSTR(err_code, 2, 1) = '0'
         AND   SUBSTR(err_code, 3, 1) = '0'
         AND   (trim(MBRSHP_NO) = '' OR MBRSHP_NO IS NULL)
         AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
         AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --   3.2 Does not exist if N stands for BHK otherswise stands for BME, Author:Tommy,Date:20040422
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 2) || '2' || SUBSTR(err_code, 4)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND   SUBSTR(err_code, 2, 1) = '0'
         AND   SUBSTR(err_code, 3, 1) = '0'
         AND   NOT Exists (SELECT 1 FROM mr_member
                              WHERE mr_member.MBRSHP_NO = MR_MBR_BAT_UPD.MBRSHP_NO)
         AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
         AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

 --3.4 Too long
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 2) || '9' || SUBSTR(err_code, 4)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         --2014-09-30 REF-1522 CR226 Nathan Start
         --AND length(trim(MBRSHP_NO))>7
         AND (length(trim(MBRSHP_NO))<7 OR length(trim(MBRSHP_NO))>8)
         --2014-09-30 REF-1522 CR226 Nathan End
         AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
         AND CRT_DATE=pc_crt_date;               -- 2006-10-13
  END IF ;
 -- 3.3 judge that is BME or is BHK
--  ls_return_value=csr.gl_lib_pkg.GET_REGPARAM_VALUE( 'MR', 'SP', 'MBRSHP_NO' );
--  IF upper(ls_return_value)='Y' THEN

--   UPDATE MR_MBR_BAT_UPD
--      SET err_code = SUBSTR(err_code, 1, 2) || '3' || SUBSTR(err_code, 4)
--   WHERE SUBSTR(err_code, 1, 1) = '0'
--   AND   SUBSTR(err_code, 2, 1) = '0'
--   AND   SUBSTR(err_code, 3, 1) = '0'

-- END IF ;
  --AND   NOT (cont_no, mbr_no) IN (SELECT cont_no, mbr_no
     --                                FROM MR_MEMBER);

  lv_valid_line := TRIM('3 OK');
     ------------------------------
ln_check := -830;
  --4. Class ID
  --   4.1 Missing value
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 3) || '1' || SUBSTR(err_code, 5)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
  AND   SUBSTR(err_code, 4, 1) = '0'
  AND   (trim(cls_id) = '''''' or trim(cls_id) = '' OR cls_id IS NULL)
  AND   adj_code = '701'
  AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
  AND CRT_DATE=pc_crt_date;               -- 2006-10-13

  --   4.2 Does not exist
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 3) || '2' || SUBSTR(err_code, 5)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 4, 1) = '0'
     AND   adj_code = '701'
     AND   NOT Exists (SELECT 1 FROM MR_CONTRACT b, MR_CONT_CLS a, MR_MEMBER c
                                WHERE a.cont_no = MR_MBR_BAT_UPD.cont_no
                                  AND a.cls_id = MR_MBR_BAT_UPD.cls_id
                                  AND a.cont_no = b.cont_no
                                  AND a.cont_yymm = b.cont_yymm
                                  AND a.cont_no = c.cont_no
                                  --2009-10-20 REF-0627 Prod-Log Laam start
                                  --AND b.eff_date <= c.eff_date
                                  --AND b.term_date >= c.eff_date)
                                  AND b.eff_date <= MR_MBR_BAT_UPD.mbr_eff_date
                                  AND b.term_date >= MR_MBR_BAT_UPD.mbr_eff_date)
                                  --2009-10-20 REF-0627 Prod-Log Laam end
     AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND CRT_DATE=pc_crt_date;               -- 2006-10-13

  --AND   NOT (cont_no, cls_id) IN (SELECT a.cont_no, a.cls_id
  --                                FROM MR_CONT_CLS a, MR_CONTRACT b
 --         WHERE a.cont_no = MR_MBR_BAT_UPD.cont_no
 --         AND   b.eff_date <= MR_MBR_BAT_UPD.mbr_eff_date
 --                     AND   b.term_date >= MR_MBR_BAT_UPD.mbr_eff_date
 --         AND   a.cont_no = b.cont_no
 --         AND   a.cont_yymm = b.cont_yymm);

  lv_valid_line := TRIM('4 OK');
ln_check := -840;
  ------------------------------
  --4.3 Too long
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 3) || '9' || SUBSTR(err_code, 5)
     WHERE SUBSTR(err_code, 1, 1) = '0'
   --2014-07-29 REF-1522 CR226 Eric Shek, Start
     --AND   length(trim(cls_id))>3
     AND   length(trim(cls_id))>5
      --2014-07-29 REF-1522 CR226 Eric Shek, End
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
  --5. Member Effective Date
  --   5.1 Missing value
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 4) || '1' || SUBSTR(err_code, 6)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 5, 1) = '0'
     AND   (mbr_eff_date = to_date('01010001','ddmmyyyy') or mbr_eff_date IS NULL)
     AND   adj_code in ('301','701')
     AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND CRT_DATE=pc_crt_date;               -- 2006-10-13

     lv_valid_line := TRIM('5.1 OK');

  --   5.3 Invalid Date
  --      This is date column, no need to check.  Import function should have handled it(??).
     --      No contract found to fit this effective date
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 4) || '3' || SUBSTR(err_code, 6)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 5, 1) = '0'
     AND   adj_code in ('301','701')
     AND   NOT EXISTS (SELECT 1 FROM MR_CONTRACT b
                          WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
                          AND   b.eff_date <= MR_MBR_BAT_UPD.mbr_eff_date
                          AND   b.term_date >= MR_MBR_BAT_UPD.mbr_eff_date)
     AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND CRT_DATE=pc_crt_date;               -- 2006-10-13

     lv_valid_line := TRIM('5.3 OK');

   --   5.4 Check Forward and Back Date
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 4) || '4' || SUBSTR(err_code, 6)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 5, 1) = '0'
     AND   adj_code in ('301','701')
     AND   mbr_eff_date <> to_date('01010001','ddmmyyyy')
     AND   mbr_eff_date IS NOT NULL
     AND  (MONTHS_BETWEEN(mbr_eff_date, ld_BatchRunDate) > li_ForwardDate OR
           MONTHS_BETWEEN(ld_BatchRunDate, mbr_eff_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     lv_valid_line := TRIM('5.4 OK');

/*
   --   5.5 Check New Effective Date not same as original effective date
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 4) || '5' || SUBSTR(err_code, 6)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 5, 1) = '0'
   AND   adj_code in ('301','701')
     AND   EXISTS (SELECT 1 FROM MR_MEMBER
       WHERE cont_no = MR_MBR_BAT_UPD.cont_no
       AND   mbr_no  = MR_MBR_BAT_UPD.mbr_no
       AND   eff_date = MR_MBR_BAT_UPD.mbr_eff_date);

     lv_valid_line := TRIM('5.5 OK');

  --   5.6 Check New Effective Date > original effective date for Class Change
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 4) || '6' || SUBSTR(err_code, 6)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 5, 1) = '0'
   AND   adj_code = '701'
  AND   mbr_eff_date < (SELECT eff_date FROM MR_MEMBER
               WHERE cont_no = MR_MBR_BAT_UPD.cont_no
            AND   mbr_no  = MR_MBR_BAT_UPD.mbr_no);
*/

  lv_valid_line := TRIM('5 OK');

ln_check := -850;
  ------------------------------
  --6. Member Termination Date
  --   6.1 Missing value
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 5) || '1' || SUBSTR(err_code, 7)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 6, 1) = '0'
     AND   mbr_term_date IS NULL
     AND   adj_code = '401'
     AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND CRT_DATE=pc_crt_date;               -- 2006-10-13

/*
  --   6.3 Termination Date is not null
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 5) || '3' || SUBSTR(err_code, 7)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
  AND   SUBSTR(err_code, 6, 1) = '0'
   AND   adj_code = '401'
  AND   mbr_term_date = to_date('01010001','ddmmyyyy')
  AND   EXISTS (SELECT 1 FROM MR_MEMBER
       WHERE cont_no = MR_MBR_BAT_UPD.cont_no
       AND   mbr_no  = MR_MBR_BAT_UPD.mbr_no
       AND   term_date is null);
*/

   --   6.4 Check Forward and Back Date
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 5) || '4' || SUBSTR(err_code, 7)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 6, 1) = '0'
     AND   adj_code = '401'
     AND   mbr_term_date <> to_date('01010001','ddmmyyyy')
     AND   mbr_term_date IS NOT NULL
     AND  (MONTHS_BETWEEN(mbr_term_date, ld_BatchRunDate) > li_ForwardDate OR
           MONTHS_BETWEEN(ld_BatchRunDate, mbr_term_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 5) || '4' || SUBSTR(err_code, 7)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 6, 1) = '0'
     AND   adj_code = '401'
     AND   (mbr_term_date = to_date('01010001','ddmmyyyy') or mbr_term_date IS NULL)
     AND   exists (select 1 from mr_member
                      where cont_no = MR_MBR_BAT_UPD.cont_no
                      AND   mbr_no = MR_MBR_BAT_UPD.mbr_no
                      AND   term_date is not null
                      AND  (MONTHS_BETWEEN(term_date, ld_BatchRunDate) > li_ForwardDate
                            OR    MONTHS_BETWEEN(ld_BatchRunDate, term_date) > li_BackDate))
     AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND CRT_DATE=pc_crt_date;               -- 2006-10-13

  --2012-11-27 REF-1156 CR164 RichardL Start
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 5) || '5' || SUBSTR(err_code, 7)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 6, 1) = '0'
     AND   adj_code = '401'
     AND   mbr_term_date <> to_date('01010001','ddmmyyyy')
     AND   mbr_term_date IS NOT NULL
     AND   DEL_REASON IS NULL 
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;
     
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 5) || '6' || SUBSTR(err_code, 7)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 6, 1) = '0'
     AND   adj_code = '401'
     AND   mbr_term_date <> to_date('01010001','ddmmyyyy')
     AND   mbr_term_date IS NOT NULL
     AND   DEL_REASON IS NOT NULL
     AND   DEL_REASON NOT IN (SELECT TRIM(SYS_CODE) FROM SY_SYS_CODE WHERE SYS_TYPE = 'WEB_SUB_REASON' AND SYS_CODE LIKE 'DEL%')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;
     
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 5) || 'A' || SUBSTR(err_code, 7)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 6, 1) = '0'
     AND   adj_code = '401'
     AND   mbr_term_date = to_date('01010001','ddmmyyyy')
     AND   REINS_REASON IS NULL 
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;
     
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 5) || 'B' || SUBSTR(err_code, 7)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 6, 1) = '0'
     AND   adj_code = '401'
     AND   mbr_term_date = to_date('01010001','ddmmyyyy')
     AND   REINS_REASON IS NOT NULL
     AND   REINS_REASON NOT IN (SELECT TRIM(SYS_CODE) FROM SY_SYS_CODE WHERE SYS_TYPE = 'WEB_SUB_REASON' AND SYS_CODE LIKE 'REI%')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;
     
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 5) || 'C' || SUBSTR(err_code, 7)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 6, 1) = '0'
     AND   adj_code = '401'
     AND   mbr_term_date <> to_date('01010001','ddmmyyyy')
     AND   mbr_term_date IS NOT NULL
     AND   DEL_REASON IS NOT NULL
     AND   REINS_REASON IS NOT NULL
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;
     
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 5) || 'D' || SUBSTR(err_code, 7)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 6, 1) = '0'
     AND   adj_code = '401'
     AND   mbr_term_date = to_date('01010001','ddmmyyyy')
     AND   REINS_REASON IS NOT NULL
     AND   DEL_REASON IS NOT NULL
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;
  --2012-11-27 REF-1156 CR164 RichardL End
     
/*
  --   6.5 terminate already term member
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 5) || '5' || SUBSTR(err_code, 7)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
  AND   SUBSTR(err_code, 6, 1) = '0'
   AND   adj_code = '401'
  AND   mbr_term_date <> to_date('01010001','ddmmyyyy')
  AND   EXISTS (SELECT 1 FROM MR_MEMBER
       WHERE cont_no = MR_MBR_BAT_UPD.cont_no
       AND   mbr_no  = MR_MBR_BAT_UPD.mbr_no
       AND   term_date is not null);

  lv_valid_line := TRIM('6 OK');
*/
ln_check := -860;
  ------------------------------
  --7. Member Title
  --   7.1 Does not exist in system code table
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 6) || '1' || SUBSTR(err_code, 8)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 7, 1) = '0'
     AND   adj_code = '000'
     AND   not (trim(title) = '''''' OR title IS NULL)
     AND   NOT Exists (SELECT 1 FROM SY_SYS_CODE
                          WHERE UPPER(sys_type) = UPPER('title')
                          AND   trim(sys_code) = trim(MR_MBR_BAT_UPD.title))
     AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND CRT_DATE=pc_crt_date;               -- 2006-10-13

 --ls_return_value :=CSR.GL_LIB_PKG.GET_REGPARAM_VALUE( 'MR', 'SP', 'MANDATORY_TITLE' );
 --Member Title is mandatory field  Author:Tommy,Date:200404242
  IF UPPER(lc_MdyTitle)='Y' THEN
     UPDATE MR_MBR_BAT_UPD
        SET err_code = SUBSTR(err_code, 1, 6) || '2' || SUBSTR(err_code, 8)
        WHERE SUBSTR(err_code, 1, 1) = '0'
        AND   SUBSTR(err_code, 2, 1) = '0'
        AND   SUBSTR(err_code, 3, 1) = '0'
        AND   SUBSTR(err_code, 7, 1) = '0'
        AND   adj_code = '000'
        AND  (trim(title) = '''''')
        AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
        AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
  END IF ;
 --Too long
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 6) || '9' || SUBSTR(err_code, 8)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND length(trim(title))>4
     AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND CRT_DATE=pc_crt_date;               -- 2006-10-13
  --AND   NOT trim(title) IN (SELECT trim(sys_code) FROM SY_SYS_CODE
  --                          WHERE UPPER(sys_type) = UPPER('title'));

  lv_valid_line := TRIM('7 OK');
/*
  ------------------------------
  --8. Member Name
  --   8.1 Missing value
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 7) || '1' || SUBSTR(err_code, 9)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
  AND   SUBSTR(err_code, 8, 1) = '0'
  AND   adj_code = '000'
  AND   (trim(mbr_name) = '''''');

  lv_valid_line := TRIM('8 OK');
*/
  --2009-07-21 CR076 REF-0608 HoLaamC start
  --Characters only
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 7) || '2' || SUBSTR(err_code, 9)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
  AND   SUBSTR(err_code, 8, 1) = '0'
  AND   adj_code = '000'
  AND   (trim(mbr_name) <> '' OR mbr_name IS NOT NULL)
  AND SY_LIB_PKG.Check_CHAR(TRIM(mbr_name)) = -1
  AND TRIM(CRT_USER)=TRIM(pc_crt_user)
  AND CRT_DATE=pc_crt_date;
  --2009-07-21 CR076 REF-0608 HoLaamC end

ln_check := -870;
     ------------------------------
  --9. Date of Birth

  --   9.1 Check if greater than Batch Run date
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 8) || '1' || SUBSTR(err_code, 10)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 9, 1) = '0'
     AND   adj_code = '000'
     AND   DOB is not Null
     AND   DOB > ld_BatchRunDate
     AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND CRT_DATE=pc_crt_date;               -- 2006-10-13

  --   9.3 DOB > Member Effective Date
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 8) || '3' || SUBSTR(err_code, 10)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 9, 1) = '0'
     AND   adj_code = '000'
     AND   DOB is not Null
     AND   DOB > (SELECT eff_date FROM MR_MEMBER
                     WHERE cont_no = MR_MBR_BAT_UPD.cont_no
                     AND   mbr_no  = MR_MBR_BAT_UPD.mbr_no)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --   9.4 Member's DOB is 15 days less than mbr effective date
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 8) || '4' || SUBSTR(err_code, 10)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 9, 1) = '0'
     AND   adj_code = '000'
     AND   DOB is not Null
     AND   ((SELECT eff_date FROM MR_MEMBER
                WHERE cont_no = MR_MBR_BAT_UPD.cont_no
                  AND mbr_no  = MR_MBR_BAT_UPD.mbr_no) - DOB) < li_BDayLimit
     AND   ((SELECT eff_date FROM MR_MEMBER
                WHERE cont_no = MR_MBR_BAT_UPD.cont_no
                  AND mbr_no  = MR_MBR_BAT_UPD.mbr_no) - DOB) >= 0
     AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND CRT_DATE=pc_crt_date;               -- 2006-10-13

--2009-07-21 CR076 REF-0608 HoLaamC start
   --2016-10-20 Teddy Chiu REF-2349 Prod Log Start
   --Commented By Teddy
   /*UPDATE MR_MBR_BAT_UPD
      SET err_code = SUBSTR(err_code, 1, 8) || '6' || SUBSTR(err_code, 10)
      WHERE SUBSTR(err_code, 1, 1) = '0'
      AND   SUBSTR(err_code, 2, 1) = '0'
      AND   SUBSTR(err_code, 3, 1) = '0'
      AND   SUBSTR(err_code, 9, 1) = '0'
      AND   adj_code = '000'
      and   dob is not null
      AND   EXISTS (SELECT 1 FROM MR_MEMBER b
                       WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
                       AND   b.mbr_no = MR_MBR_BAT_UPD.mbr_no)
      AND   (SELECT TRUNC(MONTHS_BETWEEN(a.eff_date, MR_MBR_BAT_UPD.dob)/12)
                FROM MR_CONTRACT a, MR_MEMBER b
                WHERE a.cont_no = MR_MBR_BAT_UPD.cont_no
                AND   (a.cont_yymm = Mr_Scr_Pkg.GET_CUR_CONTRACT(a.cont_no, ld_BatchRunDate)
                       OR (a.cont_yymm = Mr_Scr_Pkg.MRMEMBMNT01_Get_For_Contract(a.cont_no, ld_BatchRunDate)
                           AND '-2' = Mr_Scr_Pkg.GET_CUR_CONTRACT(a.cont_no, ld_BatchRunDate)))
                and   b.cont_no = MR_MBR_BAT_UPD.cont_no
                and   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
                AND   a.eff_date <= b.eff_date
                AND   a.term_date >= b.eff_date) >= li_MaxAge
      AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
      AND   CRT_DATE=pc_crt_date;*/
   --2016-10-20 Teddy Chiu REF-2349 Prod Log End
--2009-07-21 CR076 REF-0608 HoLaamC end

--2016-04-22 Larry REF-2134 Prod Log - Start 
/*
  --   9.5 Check for overage adults.
   UPDATE MR_MBR_BAT_UPD
      SET err_code = SUBSTR(err_code, 1, 8) || '5' || SUBSTR(err_code, 10)
      WHERE SUBSTR(err_code, 1, 1) = '0'
      AND   SUBSTR(err_code, 2, 1) = '0'
      AND   SUBSTR(err_code, 3, 1) = '0'
      AND   SUBSTR(err_code, 9, 1) = '0'
      AND   adj_code = '000'
      and   dob is not null
      AND   EXISTS (SELECT 1 FROM MR_MEMBER b
                       WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
                       AND   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
                       AND   b.mbr_type in ('E','S')) --2013-03-26 REF-1206 CR137 RichardL
      AND   (SELECT TRUNC(MONTHS_BETWEEN(a.eff_date, MR_MBR_BAT_UPD.dob)/12)
                FROM MR_CONTRACT a, MR_MEMBER b
                WHERE a.cont_no = MR_MBR_BAT_UPD.cont_no
                AND   (a.cont_yymm = Mr_Scr_Pkg.GET_CUR_CONTRACT(a.cont_no, ld_BatchRunDate)
                       OR (a.cont_yymm = Mr_Scr_Pkg.MRMEMBMNT01_Get_For_Contract(a.cont_no, ld_BatchRunDate)
                           AND '-2' = Mr_Scr_Pkg.GET_CUR_CONTRACT(a.cont_no, ld_BatchRunDate)))
                and   b.cont_no = MR_MBR_BAT_UPD.cont_no
                and   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
                AND   a.eff_date <= b.eff_date
                AND   a.term_date >= b.eff_date) > li_Overage
      AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
      AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --  9.5 Check for overage children.
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 8) || '5' || SUBSTR(err_code, 10)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 9, 1) = '0'
     AND   adj_code = '000'
     and   dob is not null
     AND   EXISTS (SELECT 1 FROM MR_MEMBER b
                      WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
                      AND   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
                      AND   b.mbr_type = 'C')
     AND  (SELECT TRUNC(MONTHS_BETWEEN(a.eff_date, MR_MBR_BAT_UPD.dob)/12)
              FROM MR_CONTRACT a, MR_MEMBER b
              WHERE a.cont_no = MR_MBR_BAT_UPD.cont_no
              and   a.cont_no = b.cont_no
              and   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
              AND   a.eff_date <= b.eff_date
              AND   a.term_date >= b.eff_date) >= (SELECT DISTINCT d.OVERAGE_CHILD_AGE
                                                      FROM MR_CONTRACT b, MR_CONT_CLS c, SR_PLAN_RATE d, MR_MEMBER e
                                                      WHERE b.cont_no = c.cont_no
                                                      and   b.cont_no = e.cont_no
                                                      and   e.mbr_no = MR_MBR_BAT_UPD.mbr_no
                                                      AND   b.cont_yymm = c.cont_yymm
                                                      AND   b.bill_cycle = d.bill_cycle
                                                      AND   d.plan_id = c.plan_id
                                                      AND   c.cls_id = e.cls_id
                                                      AND   b.cont_no = MR_MBR_BAT_UPD.cont_no
                                                      AND   b.eff_date <= e.eff_date
                                                      AND   b.term_date >= e.eff_date)
     AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND CRT_DATE=pc_crt_date;               -- 2006-10-13
*/
--2016-04-22 Larry REF-2134 Prod Log - End

  lv_valid_line := TRIM('9 OK');
  ------------------------------
  --10. Country Code
ln_check := -880;
  --10.2 Nationality is invalid
--2016-12-13 Larry REF-2403 Prod Log Start
/*
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 9) || '2' || SUBSTR(err_code, 11)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 10, 1) = '0'
     AND   adj_code = '000'
     AND   NOT ctry_code IS NULL
     AND   ctry_code='000'
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
*/
--2016-12-13 Larry REF-2403 Prod Log End

 --    10.1 Does not exist in system code table
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 9) || '1' || SUBSTR(err_code, 11)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 10, 1) = '0'
     AND   adj_code = '000'
     AND   NOT ctry_code IS NULL
     AND   NOT Exists (SELECT 1 FROM SY_SYS_CODE
--2016-12-13 Larry rEf-2403 Prod Log Start
--                          WHERE UPPER(sys_type) = UPPER('COUNTRY_CODE')
                          WHERE UPPER(sys_type) = 'COUNTRY_CODE'
--2016-12-13 Larry rEf-2403 Prod Log end
                          AND   trim(sys_code) = NVL(trim(MR_MBR_BAT_UPD.ctry_code), '0'))
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --Too long
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 9) || '9' || SUBSTR(err_code, 11)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   length(trim(ctry_code))>3
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
     
  --2015-08-11 REF-1866 Prod log Nathan Start
  --Country must be Saudi Arabia for DEL002
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 9) || '3' || SUBSTR(err_code, 11)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   TRIM(DEL_REASON) = 'DEL002'
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date
     AND NOT EXISTS (SELECT 1
                     FROM MR_MEMBER mbr
                     WHERE mbr.CONT_NO = MR_MBR_BAT_UPD.CONT_NO
                     AND mbr.MBR_NO = MR_MBR_BAT_UPD.MBR_NO
                     AND mbr.CTRY_CODE = '966');
  --2015-08-11 REF-1866 Prod log Nathan End

  lv_valid_line := TRIM('10 OK');
  ------------------------------
ln_check := -890;
  --11. Expatriate/Local Indicator
  --    11.1Does not exist
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 10) || '1' || SUBSTR(err_code, 12)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 11, 1) = '0'
     AND   adj_code = '000'
     AND   NOT exp_loc IS NULL
     AND   NOT NVL(exp_loc, '0') IN ('E', 'L')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --Too long
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 10) || '9' || SUBSTR(err_code, 12)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   length(trim(exp_loc))>1
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

 lv_valid_line := TRIM('11 OK');
  ------------------------------
ln_check := -900;
  --12. Staff No.
  --    12.1 Missing value
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 11) || '1' || SUBSTR(err_code, 13)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 12, 1) = '0'
     AND   adj_code = '000'
     AND   EXISTS (SELECT 1 FROM MR_MEMBER b
                      WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
                      AND   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
                      --AND   b.mbr_type = 'E') --2013-03-26 REF-1206 CR137 RichardL
                      --2017-11-15 Teddy Chiu REF-2671 CR380 Phase 2 Start
                      --AND   MR_BAT_PKG.GET_MBR_TYPE_GRP(b.mbr_type) = 'E') --2013-03-26 REF-1206 CR137 RichardL
					  AND   (MR_BAT_PKG.GET_MBR_TYPE_GRP(b.mbr_type) = 'E' OR pc_TPA_Ind = 'Y'))
					  --2017-11-15 Teddy Chiu REF-2671 CR380 Phase 2 End
     AND  trim(staff_no) = ''''''
     AND  EXISTS (SELECT 1 FROM MR_CUSTOMER_TBL a
                     WHERE a.cont_no = MR_MBR_BAT_UPD.cont_no
                     AND   a.STAFF_NO_IND = 'Y')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --2018-01-09 REF-2671 CR380 Phase 2 Jimmy Start
 /*
 --TA,TE cannot change
 UPDATE MR_MBR_BAT_UPD
 SET err_code = SUBSTR(err_code, 1, 11) || '2' || SUBSTR(err_code, 13)
 WHERE SUBSTR(err_code, 1, 1) = '0'
 AND SUBSTR(err_code, 12, 1) = '0'
 AND NVL(pc_TPA_Ind, 'N') = 'Y'
 AND mbr_type IN ('TA','TE')
 AND staff_no IS NOT NULL
 AND adj_code = '000'
 AND TRIM(CRT_USER)=TRIM(pc_crt_user)
 AND CRT_DATE=pc_crt_date; 
 */
 
 --NOT TA,TE Prefix must br same as TE
 UPDATE MR_MBR_BAT_UPD bat
 SET err_code = SUBSTR(err_code, 1, 11) || '3' || SUBSTR(err_code, 13)
 WHERE SUBSTR(err_code, 1, 1) = '0'
 AND SUBSTR(err_code, 12, 1) = '0'
 AND NVL(pc_TPA_Ind, 'N') = 'Y'
 AND mbr_type NOT IN ('TA','TE')
 AND SUBSTR(staff_no,1,INSTR(staff_no,'-') - 1) <>
    (SELECT staff_no FROM MR_MEMBER WHERE CONT_NO = bat.CONT_NO AND MBR_NO LIKE SUBSTR(bat.MBR_NO,1,5) || '%' AND MBR_TYPE = 'TE')
 AND adj_code = '000' 
 AND TRIM(CRT_USER)=TRIM(pc_crt_user)
 AND CRT_DATE=pc_crt_date; 
 
 --NOT TA,TE must contain '-'
 UPDATE MR_MBR_BAT_UPD
 SET err_code = SUBSTR(err_code, 1, 11) || '4' || SUBSTR(err_code, 13)
 WHERE SUBSTR(err_code, 1, 1) = '0'
 AND SUBSTR(err_code, 12, 1) = '0'
 AND NVL(pc_TPA_Ind, 'N') = 'Y'
 AND mbr_type NOT IN ('TA','TE')
 AND INSTR(staff_no,'-') = 0
 AND adj_code = '000'
 AND TRIM(CRT_USER)=TRIM(pc_crt_user)
 AND CRT_DATE=pc_crt_date; 
 
 --NOT TA,TE Suffix length 2 digits
 UPDATE MR_MBR_BAT_UPD
 SET err_code = SUBSTR(err_code, 1, 11) || '5' || SUBSTR(err_code, 13)
 WHERE SUBSTR(err_code, 1, 1) = '0'
 AND SUBSTR(err_code, 12, 1) = '0'
 AND NVL(pc_TPA_Ind, 'N') = 'Y'
 AND mbr_type NOT IN ('TA','TE')
 AND LENGTH(TRIM(SUBSTR(staff_no,INSTR(staff_no,'-') + 1))) <> 2
 AND adj_code = '000'  
 AND TRIM(CRT_USER)=TRIM(pc_crt_user)
 AND CRT_DATE=pc_crt_date; 
 
 --check exists  
 UPDATE MR_MBR_BAT_UPD u 
 SET err_code = SUBSTR(err_code, 1, 11) || '6' || SUBSTR(err_code, 13)
 where SUBSTR(err_code, 1, 1) = '0'
 AND SUBSTR(err_code, 12, 1) = '0'
 AND pc_TPA_IND = 'Y'
 and adj_code = '000'
 and staff_no is not null
 and exists(select 1 from mr_member m 
            where m.cont_no = u.cont_no and m.mbr_no <> u.mbr_no 
            and m.staff_no = u.staff_no and m.mbr_type not in ('TA', 'TE'))
 AND TRIM(CRT_USER)=TRIM(pc_crt_user)
 AND CRT_DATE=pc_crt_date;
  --2018-01-09 REF-2671 CR380 Phase 2 Jimmy End
  
  --Too long
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 11) || '9' || SUBSTR(err_code, 13)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     --AND   length(trim(staff_no))>10 --2013-07-08 REF-1287 CR189 RichardL
     AND   length(trim(staff_no))>15 --2013-07-08 REF-1287 CR189 RichardL
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  lv_valid_line := TRIM('12 OK');
     ------------------------------
ln_check := -910;
  --13. ID Card No.
  --    13.1 Missing value
  --2014-05-15 REF-1454 CR211 Nathan Start
  --UPDATE MR_MBR_BAT_UPD
--2016-07-13 Larry REF-2181 Prod Log start
--  UPDATE MR_MBR_BAT_UPD b
--  --2014-05-15 REF-1454 CR211 Nathan End
--     SET err_code = SUBSTR(err_code, 1, 12) || '1' || SUBSTR(err_code, 14)
--     WHERE SUBSTR(err_code, 1, 1) = '0'
--     AND   SUBSTR(err_code, 2, 1) = '0'
--     AND   SUBSTR(err_code, 3, 1) = '0'
--     AND   SUBSTR(err_code, 13, 1) = '0'
--     AND   adj_code = '000'
--     --2014-04-07 REF-1454 CR211 Nathan Start
--     AND ID_TYPE <> '3'
--     --2014-04-07 REF-1454 CR211 Nathan End
--     AND  trim(id_card_no) = ''''''
--     --2014-05-15 REF-1454 CR211 Nathan Start
--     AND  ((SELECT TRUNC(MONTHS_BETWEEN(eff_date, b.DOB)) FROM MR_CONTRACT WHERE CONT_NO = b.CONT_NO
--           AND b.MBR_EFF_DATE between eff_date and term_date) > 3)
--     /*AND  EXISTS (SELECT 1 FROM MR_CUSTOMER_TBL a
--                     WHERE a.cont_no = MR_MBR_BAT_UPD.cont_no
--                     AND   a.ID_NO_IND = 'Y')*/
--     AND  EXISTS (SELECT 1 FROM MR_CUSTOMER_TBL a
--                     WHERE a.cont_no = b.cont_no
--                     AND   a.ID_NO_IND = 'Y')
--     --2014-05-15 REF_1454 CR211 Nathan End
--     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
--     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
  UPDATE MR_MBR_BAT_UPD b
     SET err_code = SUBSTR(err_code, 1, 12) || '1' || SUBSTR(err_code, 14)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 13, 1) = '0'
     AND   adj_code = '000'
     AND (b.ID_TYPE <> '3'
          AND (b.id_card_no is null
               and ((b.id_type in ('1','2')
                     and exists(select 1 from mr_member m where m.cont_no=b.cont_no and m.mbr_no=b.mbr_no 
                                and id_card_no is null))
                    or
                    (b.id_type = '4' 
                     and exists(select 1 from mr_member mb where mb.cont_no=b.cont_no and mb.mbr_no=b.mbr_no 
                                and mb.border_entry_no is null))
                   )
              )
         )
     --2016-09-08 REF-2244 Prod Log Nathan Start
     --AND ((SELECT TRUNC(MONTHS_BETWEEN(eff_date, (CASE WHEN b.DOB IS NULL THEN (SELECT DOB FROM MR_MEMBER WHERE CONT_NO=b.CONT_NO AND MBR_NO=b.MBR_NO) ELSE b.DOB END)))
     AND ((SELECT TRUNC((CASE WHEN b.DOB IS NULL THEN (SELECT DOB FROM MR_MEMBER WHERE CONT_NO=b.CONT_NO AND MBR_NO=b.MBR_NO) ELSE b.DOB END) - eff_date)
     --2016-09-08 REF-2244 Prod Log Nathan End
           FROM MR_CONTRACT WHERE CONT_NO = b.CONT_NO
           AND (case when b.MBR_EFF_DATE is null then 
                 (select eff_date from mr_member where cont_no=b.cont_no and mbr_no=b.mbr_no) 
                --2016-09-08 REF-2244 Prod Log Nathan Start
                --else b.mbr_eff_date end) between eff_date and term_date) > 3)
                else b.mbr_eff_date end) between eff_date and term_date) > 365
          OR EXISTS(SELECT 1
                    FROM MR_MEMBER mbr
                    WHERE mbr.CONT_NO = b.CONT_NO AND mbr.MBR_NO = b.MBR_NO
                    AND MR_BAT_PKG.CHK_MBR_TYPE_EXEMPT(NVL(b.MBR_TYPE, mbr.MBR_TYPE)) <> 'Y')
         )
                --2016-09-08 REF-2244 Prod Log Nathan End
     AND EXISTS(SELECT 1 FROM MR_CUSTOMER_TBL a
                     WHERE a.cont_no = b.cont_no
                     AND   a.ID_NO_IND = 'Y')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;
     
     
       UPDATE MR_MBR_BAT_UPD b
     SET err_code = SUBSTR(err_code, 1, 139) || '1' || SUBSTR(err_code, 141)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   SUBSTR(err_code, 2, 1) = '0'
     AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 13, 1) = '0'
     AND   adj_code = '000'
     AND (b.ID_TYPE <> '3'
          AND (b.id_exp_date is null
               and ((b.id_type in ('1','2')
                     and exists(select 1 from mr_member m where m.cont_no=b.cont_no and m.mbr_no=b.mbr_no 
                                and id_exp_date is null))
                    or
                    (b.id_type = '4' 
                     and exists(select 1 from mr_member mb where mb.cont_no=b.cont_no and mb.mbr_no=b.mbr_no 
                                and mb.border_exp_date is null))
                   )
              )
         )
     --2016-09-08 REF-2244 Prod Log Nathan Start
     --AND ((SELECT TRUNC(MONTHS_BETWEEN(eff_date, (CASE WHEN b.DOB IS NULL THEN (SELECT DOB FROM MR_MEMBER WHERE CONT_NO=b.CONT_NO AND MBR_NO=b.MBR_NO) ELSE b.DOB END)))
     AND ((SELECT TRUNC((CASE WHEN b.DOB IS NULL THEN (SELECT DOB FROM MR_MEMBER WHERE CONT_NO=b.CONT_NO AND MBR_NO=b.MBR_NO) ELSE b.DOB END) - eff_date)
     --2016-09-08 REF-2244 Prod Log Nathan End
           FROM MR_CONTRACT WHERE CONT_NO = b.CONT_NO
           AND (case when b.MBR_EFF_DATE is null then 
                 (select eff_date from mr_member where cont_no=b.cont_no and mbr_no=b.mbr_no) 
                --2016-09-08 REF-2244 Prod Log Nathan Start
                --else b.mbr_eff_date end) between eff_date and term_date) > 3)
                else b.mbr_eff_date end) between eff_date and term_date) > 365
          OR EXISTS(SELECT 1
                    FROM MR_MEMBER mbr
                    WHERE mbr.CONT_NO = b.CONT_NO AND mbr.MBR_NO = b.MBR_NO
                    AND MR_BAT_PKG.CHK_MBR_TYPE_EXEMPT(NVL(b.MBR_TYPE, mbr.MBR_TYPE)) <> 'Y')
         )
                --2016-09-08 REF-2244 Prod Log Nathan End
     AND EXISTS(SELECT 1 FROM MR_CUSTOMER_TBL a
                WHERE a.cont_no = b.cont_no
                AND a.ID_NO_IND = 'Y')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;
     
     
--2016-07-13 Larry REF-2181 Prod Log end
    
  --2014-04-07 REF-1454 CR211 Nathan Start
  --Too long
  --Too long for ID No.
  --2014-04-07 REF-1454 CR211 Nathan End
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 12) || '9' || SUBSTR(err_code, 14)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     --2014-04-07 REF-1454 CR211 Nathan Start
     AND ID_TYPE in ('1','2')
     --AND length(trim(id_card_no))>10
     AND length(trim(id_card_no)) <> 10
     --2014-04-07 REF-1454 CR211 Nathan End
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --first char must be 1
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 12) || '2' || SUBSTR(err_code, 14)
     WHERE SUBSTR(err_code, 1, 1) = '0'
/* 2007-07-26, START
  --20060922 Start
  --AND substr(trim(id_card_no),1,1) not in ('1','2');
  AND substr(trim(id_card_no),1,1) not in ('1','2', '3')
  --20060922 End
*/
/* 2007-09-03 REF-0480, START
     AND substr(trim(id_card_no),1,1) not in ('1','2', '3', '5')
-- 2007-07-26, END
*/
--2010-09-14 REF-0727 CR092 TRISTA START
--     AND substr(trim(id_card_no),1,1) not in ('1','2','3','4','5')
     --2014-04-07 REF-1454 CR211 Nathan Start
     --AND substr(trim(id_card_no),1,1) not in ('1','2','3','5')
     --2017-03-16 REF-2505 Prod Log Nathan Start
     --AND ID_TYPE in ('1','2')
     --AND substr(trim(id_card_no),1,1) not in ('1','2')
     AND ID_TYPE = '1'
     AND substr(trim(id_card_no),1,1) <> '1'
     --2017-03-16 REF-2505 Prod Log Nathan End
     --2014-04-07 REF-1454 CR211 Nathan End
--2010-09-14 REF-0727 CR092 TRISTA END
-- 2007-09-03 REF-0480, END
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
  
    --2017-03-16 REF-2505 Prod Log Nathan Start
    --Iqama must start with 2
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 12) || 'B' || SUBSTR(err_code, 14)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND ID_TYPE = '2'
     AND substr(trim(id_card_no),1,1) <> '2'
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;
    --2017-03-16 REF-2505 Prod Log Nathan End

  --2014-04-07 REF-1454 CR211 Nathan Start
  --Removed Country-related validation since the ID No. Validation now depends on the ID Type
  --first char must be 1 for country code 966
--  UPDATE MR_MBR_BAT_UPD
--     SET err_code = SUBSTR(err_code, 1, 12) || '3' || SUBSTR(err_code, 14)
--     WHERE SUBSTR(err_code, 1, 1) = '0'
--     AND trim(CTRY_CODE) = '966'
--     AND trim(id_card_no) is not null
--     and substr(trim(id_card_no),1,1) <> '1'
--     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
--     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

-- 2007-09-03 REF-0480, START
--  UPDATE MR_MBR_BAT_UPD
--     SET err_code = SUBSTR(err_code, 1, 12) || '3' || SUBSTR(err_code, 14)
--     WHERE SUBSTR(err_code, 1, 1) = '0'
--     AND   CTRY_CODE IS NULL
--     AND   trim(id_card_no) is not null
--     and   substr(trim(id_card_no),1,1) <> '1'
--     AND   exists (select 1 from mr_member m
--                      where m.cont_no = trim(MR_MBR_BAT_UPD.cont_no)
--                        and m.mbr_no = trim(MR_MBR_BAT_UPD.mbr_no)
--                        and trim(nvl(m.ctry_code, ' ')) = '966')
--     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
--     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

--  UPDATE MR_MBR_BAT_UPD
--     SET err_code = SUBSTR(err_code, 1, 12) || '4' || SUBSTR(err_code, 14)
--     WHERE SUBSTR(err_code, 1, 1) = '0'
--     AND   TRIM(CTRY_CODE) IS NOT NULL
--     AND   TRIM(CTRY_CODE) <> '966'
--     AND   trim(id_card_no) is not null
--     and   substr(trim(id_card_no),1,1) not in ('2','3','4','5')
--     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
--     AND   CRT_DATE=pc_crt_date;

--  UPDATE MR_MBR_BAT_UPD
--     SET err_code = SUBSTR(err_code, 1, 12) || '4' || SUBSTR(err_code, 14)
--     WHERE SUBSTR(err_code, 1, 1) = '0'
--     AND   CTRY_CODE IS NULL
--     AND   trim(id_card_no) is not null
--     AND   exists (select 1 from mr_member m
--                      where m.cont_no = trim(MR_MBR_BAT_UPD.cont_no)
--                        and m.mbr_no = trim(MR_MBR_BAT_UPD.mbr_no)
--                        and trim(nvl(m.ctry_code, ' ')) <> '966')
--     and   substr(trim(id_card_no),1,1) not in ('2','3','4','5')
--     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
--     AND   CRT_DATE=pc_crt_date;
-- 2007-09-03 REF-0480, END
  
  --Too Long for Border Entry No.
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 12) || '3' || SUBSTR(err_code, 14)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND ID_TYPE = '4'
     AND trim(id_card_no) is not null
     AND length(trim(id_card_no)) > 10
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;
     
  --Border Entry No. does not start with '3', '4' or '5'
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 12) || '4' || SUBSTR(err_code, 14)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND ID_TYPE = '4'
     AND trim(id_card_no) is not null
     and substr(trim(id_card_no),1,1) not in ('3','4','5')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;
  --2014-04-07 REF-1454 CR211 Nathan End

  --Check numeric
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 12) || '8' || SUBSTR(err_code, 14)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND trim(id_card_no) is not null
     AND sy_lib_pkg.chknum(trim(id_card_no)) = -1
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --Check duplicate (National ID and Iqama)
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 12) || '7' || SUBSTR(err_code, 14)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND trim(id_card_no) is not null
     --2014-12-03 REF-1639 Prod Log Eric Shek, Start
     --AND ID_TYPE IN ('1', '2') --2014-06-09 REF-1491 Prod Log Nathan
     --2014-12-03 REF-1639 Prod Log Eric Shek, End
     AND mr_scr_cchi_pkg.IDNoDup(id_card_no,cont_no,mbr_no) is not null
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
     
  --2014-06-09 REF-1491 Prod Log Nathan Start
  --Check duplicate (Border Entry)
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 12) || '6' || SUBSTR(err_code, 14)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND trim(id_card_no) is not null
  AND ID_TYPE = '4'
  AND MR_SCR10_PKG.CHECK_OTHER_ID_EXISTS(id_card_no, id_type, cont_no, mbr_no) = 'Y'
  AND TRIM(CRT_USER)=TRIM(pc_crt_user)
  AND CRT_DATE=pc_crt_date;
  --2014-06-09 REF-1491 Prod Log Nathan End

  --Check duplicate
  UPDATE MR_MBR_BAT_UPD a
     SET a.err_code = SUBSTR(a.err_code, 1, 12) || '7' || SUBSTR(a.err_code, 14)
     WHERE SUBSTR(a.err_code, 1, 1) = '0'
     AND trim(a.id_card_no) is not null
     AND EXISTS (SELECT * FROM MR_MBR_BAT_UPD b
                    WHERE trim(b.id_card_no) is not null
               --20061103 Start
       --AND (b.CONT_NO <> a.cont_no or b.MBR_NO <> a.mbr_no)
                AND not (b.CONT_NO = a.cont_no and b.MBR_NO = a.mbr_no)
                and b.cont_no=a.cont_no
                AND TRIM(b.CRT_USER)=TRIM(pc_crt_user) -- REF-0494
                AND b.CRT_DATE=pc_crt_date             -- REF-0494
                --20061103 End
        AND trim(b.id_card_no) = trim(a.id_card_no))
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13


  --2014-12-29 Larry REF-1667 Prod Log - Start
  --Check ID Type vs Nationality
  --2015-11-06 REF-1957 CR283 Nathan Start
  --UPDATE MR_MBR_BAT_CRT a
  --2017-03-15 REF-2502 CR311 Nathan Start
  --commented, validation shall be handled by the ID Type Err. Code
  /*UPDATE MR_MBR_BAT_UPD a
  --2015-11-06 REF-1957 CR283 Nathan End
  SET a.err_code = SUBSTR(a.err_code, 1, 12) || '5' || SUBSTR(a.err_code, 14)
  WHERE SUBSTR(a.err_code, 1, 1) = '0'
  AND trim(a.id_card_no) is not null
  AND (ID_TYPE = '1' AND TRIM(ctry_code) <> '966')
  AND TRIM(CRT_USER)=TRIM(pc_crt_user)
  AND CRT_DATE=pc_crt_date;*/
  --2017-03-15 REF-2502 CR311 Nathan End
  --2014-12-29 Larry REF-1667 Prod Log - End

  --2015-11-06 REF-1957 CR283 Nathan Start
  --ID / Border Entry No. has been blocked
  UPDATE MR_MBR_BAT_UPD a
  SET a.err_code = SUBSTR(a.err_code, 1, 12) || 'A' || SUBSTR(a.err_code, 14)
  WHERE SUBSTR(a.err_code, 1, 1) = '0'
  AND trim(a.id_card_no) is not null
  AND ID_TYPE IN ('1', '2', '4')
  AND MR_SCR7_PKG.CHK_ID_BLOCKED(a.ID_CARD_NO, a.ID_TYPE, NULL) = 'Y'
  AND TRIM(CRT_USER)=TRIM(pc_crt_user)
  AND CRT_DATE=pc_crt_date;
  --2015-11-06 REF-1957 CR283 Nathan End
  
  lv_valid_line := TRIM('13 OK');
     ------------------------------

 --104. Sponsor ID.
 --2017-11-15 Teddy Chiu REF-2671 CR380 Phase 2 Start
 --Reopen this rule
 IF pc_TPA_Ind = 'Y' THEN
  UPDATE MR_MBR_BAT_CRT
  SET err_code = SUBSTR(err_code, 1, 103) || '3' || SUBSTR(err_code, 105)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND  (trim(SPONSOR_ID) = '' OR SPONSOR_ID IS NULL);
 END IF;
 --2017-11-15 Teddy Chiu REF-2671 CR380 Phase 2 End

  --Too long
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 103) || '9' || SUBSTR(err_code, 105)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   length(trim(SPONSOR_ID)) > 10
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --first char must be 1,2 ,7
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 103) || '2' || SUBSTR(err_code, 105)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   substr(SPONSOR_ID,1,1) not in ('1','2','7')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --Check numeric
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 103) || '8' || SUBSTR(err_code, 105)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND rtrim(SPONSOR_ID) IS NOT NULL
     AND sy_lib_pkg.chknum(trim(SPONSOR_ID)) = -1
     AND TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND CRT_DATE=pc_crt_date;               -- 2006-10-13

  --2020-12-14 REF-3353 Prod Log Kim Start
  --Check if sponsor id exists OR sponsor id = employee ID card no
  UPDATE MR_MBR_BAT_UPD upd
    SET upd.err_code = SUBSTR(upd.err_code, 1, 103) || '4' || SUBSTR(upd.err_code, 105)
    WHERE SUBSTR(upd.err_code, 1, 1) = '0'
    AND SUBSTR(upd.err_code, 104, 1) = '0'
    AND RTRIM(upd.sponsor_id) IS NOT NULL
	AND NVL(upd.SPID_VALIDATE_IND, ' ') <> 'N'	--2021-06-08 Teddy Chiu REF-3548 CR603
    AND NOT EXISTS(
        SELECT 1 FROM MR_SPONSOR_ID sp
        WHERE upd.cont_no = sp.cont_no
        AND upd.sponsor_id = sp.sponsor_id)
    AND NOT EXISTS(
        SELECT 1 FROM MR_MEMBER mbr_dep
        WHERE mbr_dep.cont_no = upd.cont_no
        AND mbr_dep.mbr_no = upd.mbr_no
        AND MR_BAT_PKG.GET_MBR_TYPE_GRP(mbr_dep.mbr_type) <> 'E' 
        AND EXISTS(
            SELECT 1 FROM MR_MEMBER mbr_main
            WHERE SUBSTR(mbr_dep.mbr_no,1,5) = SUBSTR(mbr_main.mbr_no,1,5)
            AND mbr_dep.cont_no = upd.cont_no
            AND MR_BAT_PKG.GET_MBR_TYPE_GRP(mbr_main.mbr_type) = 'E' 
            AND mbr_main.id_card_no = upd.sponsor_id
        )
    )
    AND TRIM(crt_user) = TRIM(pc_crt_user)
    AND crt_date = pc_crt_date;
  --2020-12-14 REF-3353 Prod Log Kim End

  --2012-9-3 REF-1105 CR126 No need
  /*
  EXECUTE IMMEDIATE 'TRUNCATE TABLE MR_MBR_BATCH_SPONSOR_UPD drop storage';

  INSERT INTO MR_MBR_BATCH_SPONSOR_UPD
  SELECT CONT_NO,MBR_NO,SPONSOR_ID
  FROM MR_MBR_BAT_UPD
  WHERE trim(SPONSOR_ID) IS NOT NULL
  AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
  AND   CRT_DATE=pc_crt_date;

  UPDATE MR_MBR_BAT_UPD b
    SET err_code = SUBSTR(err_code, 1, 103) || '7' || SUBSTR(err_code, 105)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND SUBSTR(err_code, 104, 1) = '0'
     and exists (select 1 from MR_MBR_BAT_UPD a
                     WHERE trim(SPONSOR_ID) IS NOT NULL
                     AND SUBSTR(err_code, 1, 1) = '0'
                     AND SUBSTR(err_code, 104, 1) = '0'
                     AND TRIM(CRT_USER)=TRIM(pc_crt_user)
                     AND CRT_DATE=pc_crt_date
                     AND a.CONT_NO = b.CONT_NO
                     AND a.adj_code = b.adj_code
                     GROUP BY a.CONT_NO
                     HAVING MR_SCR_MEMBMNT_PKG.CHECK_SPONSOR_ID_BAT(a.cont_no,TRIM(pc_crt_user),pc_crt_date,'U') = 0
                     )
     AND trim(SPONSOR_ID) IS NOT NULL
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;

  UPDATE MR_MBR_BAT_UPD b
    SET err_code = SUBSTR(err_code, 1, 103) || '7' || SUBSTR(err_code, 105)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND SUBSTR(err_code, 104, 1) = '0'
    AND ADJ_CODE = '401'
    AND (MBR_TERM_DATE is null or MBR_TERM_DATE = to_date('01010001','ddmmyyyy'))
    AND (SELECT MULTI_SPONSOR_ID FROM MR_CUSTOMER_TBL WHERE CONT_NO = b.cont_no) <
        (SELECT COUNT(DISTINCT SPONSOR_ID)
        FROM MR_MEMBER
        WHERE SPONSOR_ID IS NOT NULL
        AND CONT_NO = b.cont_no
        AND (STATUS = 'A' OR
            (CONT_NO = b.CONT_NO
             AND MBR_NO = b.MBR_NO)
             )
        )
    AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND   CRT_DATE=pc_crt_date;
  */

  --105 Outside KSA Ind
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 104) || '1' || SUBSTR(err_code, 106)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND OUTSIDE_RES_IND IS NOT NULL
     AND trim(OUTSIDE_RES_IND) NOT IN ('N','Y')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --Too long
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 104) || '9' || SUBSTR(err_code, 106)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND length(trim(OUTSIDE_RES_IND)) > 1
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  -------------------------------

  --106. Passport No.
  --2016-10-14 REF-2244 Nathan Start
  --UPDATE MR_MBR_BAT_UPD
  UPDATE MR_MBR_BAT_UPD b
  --2016-10-14 REF-2244 Nathan End
     SET err_code = SUBSTR(err_code, 1, 105) || '1' || SUBSTR(err_code, 107)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   trim(OUTSIDE_RES_IND) = 'Y'
     AND   ID_TYPE = '3'--2014-04-07 REF-1454 CR211 Nathan
     AND  (trim(passport_no) = '' OR passport_no IS NULL)
     --2016-10-14 REF-2244 Nathan Start
     AND ((SELECT TRUNC((CASE WHEN b.DOB IS NULL THEN (SELECT DOB FROM MR_MEMBER WHERE CONT_NO=b.CONT_NO AND MBR_NO=b.MBR_NO) ELSE b.DOB END) - eff_date)
           FROM MR_CONTRACT WHERE CONT_NO = b.CONT_NO
           AND (case when b.MBR_EFF_DATE is null then 
                 (select eff_date from mr_member where cont_no=b.cont_no and mbr_no=b.mbr_no)
                else b.mbr_eff_date end) between eff_date and term_date) > 365
          OR EXISTS(SELECT 1
                    FROM MR_MEMBER mbr
                    WHERE mbr.CONT_NO = b.CONT_NO AND mbr.MBR_NO = b.MBR_NO
                    AND MR_BAT_PKG.CHK_MBR_TYPE_EXEMPT(NVL(b.MBR_TYPE, mbr.MBR_TYPE)) <> 'Y')
         )
     AND EXISTS(SELECT 1 FROM MR_CUSTOMER_TBL a
                     WHERE a.cont_no = b.cont_no
                     AND   a.ID_NO_IND = 'Y')
     --2016-10-14 REF-2244 Nathan End
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 105) || '9' || SUBSTR(err_code, 107)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   ID_TYPE = '3'--2014-04-07 REF-1454 CR211 Nathan
     --2014-05-16 REF-1454 CR211 Nathan Start
     --AND   length(trim(passport_no))>12
     AND   length(trim(passport_no))>15
     --2014-05-16 REF-1454 CR211 Nathan End
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
  
  --2014-06-09 REF-1491 Prod Log Nathan Start
  --Passport No Duplicate
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 105) || '7' || SUBSTR(err_code, 107)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND (trim(passport_no) <> '' OR passport_no IS NOT NULL)
  AND MR_SCR10_PKG.CHECK_OTHER_ID_EXISTS(passport_no, id_type, cont_no, mbr_no) = 'Y'
  AND TRIM(CRT_USER)=TRIM(pc_crt_user)
  AND CRT_DATE=pc_crt_date;
  --2014-06-09 REF-1491 Prod Log Nathan End
  
  --2015-11-06 REF-1957 CR283 Nathan Start
  --Passport No. has been blocked
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 105) || '2' || SUBSTR(err_code, 107)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND (trim(passport_no) <> '' OR passport_no IS NOT NULL)
  AND ID_TYPE = '3'
  AND MR_SCR7_PKG.CHK_ID_BLOCKED(PASSPORT_NO, ID_TYPE, NULL) = 'Y'
  AND TRIM(CRT_USER)=TRIM(pc_crt_user)
  AND CRT_DATE=pc_crt_date;
  --2015-11-06 REF-1957 CR283 Nathan End
  
  --2014-05-19 REF-1454 CR211 Eric Shek Start - Remove Numeric Validation logic for passport field
  --Check numeric
  /*
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 105) || '8' || SUBSTR(err_code, 107)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND   ID_TYPE = '3'--2014-04-07 REF-1454 CR211 Nathan
     AND trim(passport_no) is not null
     AND sy_lib_pkg.chknum(trim(passport_no)) = -1
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
     */
  --2014-05-19 REF-1454 CR211 Eric Shek End - Remove Numeric Validation logic for passport field
    ------------------------------

ln_check := -920;
  --14. Department Code
  --    14.1 Missing value
  IF NVL(pc_TPA_Ind, 'N') <> 'Y' THEN	--2017-11-15 Teddy Chiu REF-2671 CR380 Phase 2
	  UPDATE MR_MBR_BAT_UPD
		 SET err_code = SUBSTR(err_code, 1, 13) || '1' || SUBSTR(err_code, 15)
		 WHERE SUBSTR(err_code, 1, 1) = '0'
		 AND   SUBSTR(err_code, 2, 1) = '0'
		 AND   SUBSTR(err_code, 3, 1) = '0'
		 AND   SUBSTR(err_code, 14, 1) = '0'
		 AND   adj_code = '000'
		 AND   EXISTS (SELECT 1 FROM MR_MEMBER b
						  WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
						  AND   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
						  AND   b.mbr_type = 'E')
		 AND  trim(dept_code) = ''''''
		 AND  EXISTS (SELECT 1 FROM MR_CUSTOMER_TBL a
						 WHERE a.cont_no = MR_MBR_BAT_UPD.cont_no
						 AND   a.DEPT_CODE_IND = 'Y')
		 AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
		 AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
  END IF;	--2017-11-15 Teddy Chiu REF-2671 CR380 Phase 2

     --Too long
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 13) || '9' || SUBSTR(err_code, 15)
     WHERE SUBSTR(err_code, 1, 1) = '0'
     AND length(trim(dept_code))>50
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  lv_valid_line := TRIM('14 OK');
  
--2013-03-12 REF-1206 CR137 RichardL START
  ------------------------------
--15. Member Type
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 14) || '1' || SUBSTR(err_code, 16)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND   SUBSTR(err_code, 2, 1) = '0'
    AND   SUBSTR(err_code, 3, 1) = '0'
    AND   SUBSTR(err_code, 6, 1) = '0'
    AND   adj_code = '350'
    AND   MBR_TYPE IS NULL 
    AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND   CRT_DATE=pc_crt_date;

    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 14) || '2' || SUBSTR(err_code, 16)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND   SUBSTR(err_code, 2, 1) = '0'
    AND   SUBSTR(err_code, 3, 1) = '0'
    AND   SUBSTR(err_code, 6, 1) = '0'
    AND   adj_code = '350'
    AND   MBR_TYPE_EFF_DATE IS NULL 
    AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND   CRT_DATE=pc_crt_date;
     
    UPDATE MR_MBR_BAT_UPD bat
    SET bat.err_code = SUBSTR(bat.err_code, 1, 14) || '3' || SUBSTR(bat.err_code, 16)
    WHERE SUBSTR(bat.err_code, 1, 1) = '0'
    AND   SUBSTR(bat.err_code, 2, 1) = '0'
    AND   SUBSTR(bat.err_code, 3, 1) = '0'
    AND   SUBSTR(bat.err_code, 6, 1) = '0'
    AND   bat.adj_code = '350'
    AND   bat.MBR_TYPE IS NOT NULL
    AND   bat.MBR_TYPE_EFF_DATE IS NOT NULL
    AND   NOT EXISTS(SELECT 1 FROM MR_MBR_RATE_TYPE WHERE MBR_TYPE = bat.MBR_TYPE)
    AND   TRIM(bat.CRT_USER)=TRIM(pc_crt_user)
    AND   bat.CRT_DATE=pc_crt_date;
     
    UPDATE MR_MBR_BAT_UPD bat
    SET bat.err_code = SUBSTR(bat.err_code, 1, 14) || '4' || SUBSTR(bat.err_code, 16)
    WHERE SUBSTR(bat.err_code, 1, 1) = '0'
    AND   SUBSTR(bat.err_code, 2, 1) = '0'
    AND   SUBSTR(bat.err_code, 3, 1) = '0'
    AND   SUBSTR(bat.err_code, 6, 1) = '0'
    AND   bat.adj_code = '350'
    AND   bat.MBR_TYPE IS NOT NULL
    AND   bat.MBR_TYPE_EFF_DATE IS NOT NULL
    AND   EXISTS(SELECT 1 FROM MR_MBR_RATE_TYPE WHERE MBR_TYPE = bat.MBR_TYPE)
    AND   (SELECT STATUS FROM MR_MBR_RATE_TYPE WHERE MBR_TYPE = bat.MBR_TYPE) <> 'A'
    AND   TRIM(bat.CRT_USER)=TRIM(pc_crt_user)
    AND   bat.CRT_DATE=pc_crt_date;
    
    UPDATE MR_MBR_BAT_UPD bat
    SET bat.err_code = SUBSTR(bat.err_code, 1, 14) || '5' || SUBSTR(bat.err_code, 16)
    WHERE SUBSTR(bat.err_code, 1, 1) = '0'
    AND   SUBSTR(bat.err_code, 2, 1) = '0'
    AND   SUBSTR(bat.err_code, 3, 1) = '0'
    AND   SUBSTR(bat.err_code, 6, 1) = '0'
    AND   bat.adj_code = '350'
    AND   bat.MBR_TYPE IS NOT NULL
    AND   bat.MBR_TYPE_EFF_DATE IS NOT NULL
    AND   EXISTS(SELECT 1 FROM MR_MBR_RATE_TYPE WHERE MBR_TYPE = bat.MBR_TYPE)
    AND   (SELECT STATUS FROM MR_MBR_RATE_TYPE WHERE MBR_TYPE = bat.MBR_TYPE) = 'A'
    AND   (SELECT GRP_TYPE FROM MR_MBR_RATE_TYPE WHERE MBR_TYPE = bat.MBR_TYPE) <> 
          (SELECT GRP_TYPE FROM MR_MBR_RATE_TYPE WHERE MBR_TYPE = (SELECT MBR_TYPE FROM MR_MEMBER WHERE CONT_NO = bat.CONT_NO AND MBR_NO = bat.MBR_NO))
    AND   TRIM(bat.CRT_USER)=TRIM(pc_crt_user)
    AND   bat.CRT_DATE=pc_crt_date;
    
    -- 2014-04-04 CR213 UAT Fix Eric Shek, Start
    UPDATE MR_MBR_BAT_UPD bat
    SET err_code = SUBSTR(err_code, 1, 14) || '8' || SUBSTR(err_code, 16)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND   SUBSTR(err_code, 2, 1) = '0'
    AND   SUBSTR(err_code, 3, 1) = '0'
    AND   SUBSTR(err_code, 6, 1) = '0'
    AND   adj_code = '350'
    AND   EXISTS( SELECT 1 FROM MR_MBR_RATE_TYPE WHERE MBR_TYPE = bat.MBR_TYPE 
                    AND ( ACCEPTED_GENDER <> 'MF' AND ACCEPTED_GENDER <> (SELECT SEX FROM MR_MEMBER WHERE MBRSHP_NO = bat.MBRSHP_NO) )
        )
    AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND   CRT_DATE=pc_crt_date;
    -- 2014-04-04 CR213 UAT Fix Eric Shek, End
    
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 14) || '9' || SUBSTR(err_code, 16)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND   SUBSTR(err_code, 2, 1) = '0'
    AND   SUBSTR(err_code, 3, 1) = '0'
    AND   SUBSTR(err_code, 6, 1) = '0'
    AND   adj_code = '350'
    --2014-04-04 CR213 UAT Fix Eric Shek, Start
    --AND   length(trim(MBR_TYPE)) > 1
    AND   length(trim(MBR_TYPE)) > 2
    ----2014-04-04 CR213 UAT Fix Eric Shek, End
    AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND   CRT_DATE=pc_crt_date;

    UPDATE MR_MBR_BAT_UPD bat
    SET bat.ERR_CODE = SUBSTR (bat.ERR_CODE, 1, 14) || 'A' || SUBSTR(ERR_CODE, 16)
    WHERE SUBSTR(bat.err_code, 1, 1) = '0'
    AND   SUBSTR(bat.err_code, 2, 1) = '0'
    AND   SUBSTR(bat.err_code, 3, 1) = '0'
    AND   SUBSTR(bat.err_code, 6, 1) = '0'
    AND   bat.adj_code = '350'
    AND NOT EXISTS
    (
    SELECT 1 FROM MR_CONTCLS_MBRTYPE 
    WHERE CONT_NO = bat.CONT_NO
    AND CLS_ID = (SELECT CLS_ID FROM MR_MEMBER WHERE CONT_NO = bat.CONT_NO AND MBR_NO = bat.MBR_NO)
    --2014-05-30 Hot Fix Eric
    AND CONT_YYMM = CL_BAT_PKG.GETCURCONT(CONT_NO,bat.MBR_TYPE_EFF_DATE)
    --AND CONT_YYMM = CL_BAT_PKG.GETCURCONT(CONT_NO,SYSDATE)
    --2014-05-30 Hot Fix Eric
    AND MBR_TYPE = bat.MBR_TYPE
    )
    AND TRIM (CRT_USER) = TRIM (PC_CRT_USER)
    AND CRT_DATE = PC_CRT_DATE;
     
--2013-03-12 REF-1206 CR137 RichardL END
  
    --2017-11-15 Teddy Chiu REF-2671 CR380 Phase 2 Start
	IF pc_TPA_Ind = 'Y' THEN
		UPDATE MR_MBR_BAT_UPD bat
		SET bat.ERR_CODE = SUBSTR (bat.ERR_CODE, 1, 14) || 'B' || SUBSTR(ERR_CODE, 16)
		WHERE SUBSTR(bat.err_code, 1, 1) = '0'
		AND   SUBSTR(bat.err_code, 2, 1) = '0'
		AND   SUBSTR(bat.err_code, 3, 1) = '0'
		AND   SUBSTR(bat.err_code, 6, 1) = '0'
		AND (SELECT GRP_TYPE FROM MR_MBR_RATE_TYPE WHERE MBR_TYPE = bat.MBR_TYPE) = 'E'
		AND TRIM (CRT_USER) = TRIM (PC_CRT_USER)
		AND CRT_DATE = PC_CRT_DATE;
	END IF;
	--2017-11-15 Teddy Chiu REF-2671 CR380 Phase 2 End
  
  ------------------------------
ln_check := -930;
  --16. Payment Method
     -- Does not exist
  IF ls_return_value='BHK' THEN
   UPDATE MR_MBR_BAT_UPD
   SET err_code = SUBSTR(err_code, 1, 15) || '1' || SUBSTR(err_code, 17)
   WHERE SUBSTR(err_code, 1, 1) = '0'
   AND   SUBSTR(err_code, 2, 1) = '0'
   AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 16, 1) = '0'
   AND   adj_code = '000'
   AND   EXISTS (SELECT 1
                 FROM MR_MEMBER b
        WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
                 AND   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
        --AND   b.mbr_type = 'E') --2013-03-26 REF-1206 CR137 RichardL
        AND   MR_BAT_PKG.GET_MBR_TYPE_GRP(b.mbr_type) = 'E') --2013-03-26 REF-1206 CR137 RichardL
   AND   NOT trim(clm_pay_method) IN ('AT', 'CQ', '''''')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  ELSE
    UPDATE MR_MBR_BAT_UPD
   SET err_code = SUBSTR(err_code, 1, 15) || '1' || SUBSTR(err_code, 17)
   WHERE SUBSTR(err_code, 1, 1) = '0'
   AND   SUBSTR(err_code, 2, 1) = '0'
   AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 16, 1) = '0'
   AND   adj_code = '000'
         AND   NOT trim(clm_pay_method) = '''''' and NOT trim(clm_pay_method) is null
   AND   EXISTS (SELECT 1
                 FROM MR_MEMBER b
        WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
                 AND   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
        --AND   b.mbr_type = 'E') --2013-03-26 REF-1206 CR137 RichardL
        AND   MR_BAT_PKG.GET_MBR_TYPE_GRP(b.mbr_type) = 'E') --2013-03-26 REF-1206 CR137 RichardL
   AND  NOT EXISTS (SELECT 1
            FROM SY_SYS_CODE C
        WHERE TRIM(C.SYS_CODE)=MR_MBR_BAT_UPD.clm_pay_method)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  END IF;
     --Too long
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 15) || '9' || SUBSTR(err_code, 17)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND length(trim(clm_pay_method))>2
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

 lv_valid_line := TRIM('16 OK');
  ------------------------------
ln_check := -940;
  --17. Bank Account Number
  -- Missing value
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 16) || '1' || SUBSTR(err_code, 18)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
  AND   SUBSTR(err_code, 17, 1) = '0'
  AND   adj_code = '000'
  AND   EXISTS (SELECT 1 FROM MR_MEMBER b
                WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
                AND   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
                --AND   b.mbr_type in ('A', 'E')) --2013-03-26 REF-1206 CR137 RichardL
                AND   MR_BAT_PKG.GET_MBR_TYPE_GRP(b.mbr_type) = 'E') --2013-03-26 REF-1206 CR137 RichardL
  AND   UPPER(clm_pay_method) = 'AT'
  AND   (trim(iban) = '''''' OR trim(iban) = '' OR iban IS NULL)--REF0625 WilliamW 16/10/2009
  and   (trim(clm_swift_code) is not null or clm_branch_name is not null) /*and --2010-01-04 Raymond CR080 fix
                EXISTS (SELECT 1 FROM MR_MEMBER b
                        WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
                        AND   b.mbr_no like substr(MR_MBR_BAT_UPD.mbr_no, 1, 5) || '%'
                        AND   b.mbr_type in ('A', 'E')
                        AND   trim(b.pay_acct_no) is NULL) )*/
  AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
  AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

--start REF0625 WilliamW 16/10/2009
     --Too long
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 16) || '9' || SUBSTR(err_code, 18)
  WHERE SUBSTR(err_code, 1, 1) = '0'
 AND iban is not null
 AND length(trim(iban))>34
 AND TRIM(CRT_USER)=TRIM(pc_crt_user) -- 2006-11-02
 AND CRT_DATE=pc_crt_date; -- 2006-11-02
 --Too short
 UPDATE MR_MBR_BAT_UPD
 SET err_code = SUBSTR(err_code, 1, 16) || '8' || SUBSTR(err_code, 18)
 WHERE SUBSTR(err_code, 1, 1) = '0'
 AND iban is not null
 AND length(trim(iban)) <24
 AND TRIM(CRT_USER)=TRIM(pc_crt_user) -- 2006-11-02
 AND CRT_DATE=pc_crt_date;

 --contains non-numeric/non-alphabet characters

 UPDATE MR_MBR_BAT_UPD
 SET err_code = SUBSTR(err_code, 1, 16) || '7' || SUBSTR(err_code, 18)
 WHERE SUBSTR(err_code, 1, 1) = '0'
 AND TRIM(CRT_USER)=TRIM(pc_crt_user) -- 2006-11-02
 AND CRT_DATE=pc_crt_date -- 2006-11-02
 AND iban is not null   --REF0625 WilliamW 24/12/2009
 AND MR_BAT_PKG.checkIBANFormat(iban) = -1;
 --end REF0625 WilliamW 16/10/2009


--  AND  ((trim(pay_acct_no) = '''''' OR trim(pay_acct_no) = '' OR pay_acct_no IS NULL)
--        AND (EXISTS (SELECT 1
--            FROM MR_MEMBER b
--      WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
--            AND   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
--      AND   b.pay_acct_no is null)));
/*
  --17. Bank Account Number
  -- Missing value
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 16) || '1' || SUBSTR(err_code, 18)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
  AND   SUBSTR(err_code, 17, 1) = '0'
  AND   adj_code = '000'
  AND   clm_pay_method IS NULL
  AND   EXISTS (SELECT 1
                FROM MR_MEMBER b
       WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
                AND   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
       AND   b.clm_pay_method = 'AT')
  AND  trim(pay_acct_no) = '''''';
*/

   lv_valid_line := TRIM('17 OK');


     ------------------------------
  --18. Maternity Effective Date
  --    18.1 Check missing value
/*
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 17) || '1' || SUBSTR(err_code, 19)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 18, 1) = '0'
  AND   adj_code = '201'
  AND   m_eff_date IS NULL;
*/

  --    18.3 Check clear field but not change optional benefit
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 17) || '3' || SUBSTR(err_code, 19)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 18, 1) = '0'
  AND   adj_code <> '901'
  AND   m_eff_date = to_date('01010001','ddmmyyyy')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --    18.4 Check Forward and Back Date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 17) || '4' || SUBSTR(err_code, 19)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 18, 1) = '0'
  AND   adj_code in ('201','901')
  AND   m_eff_date <> to_date('01010001','ddmmyyyy')
  AND   m_eff_date IS NOT NULL
  AND  (MONTHS_BETWEEN(m_eff_date, ld_BatchRunDate) > li_ForwardDate
  OR    MONTHS_BETWEEN(ld_BatchRunDate, m_eff_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --    18.5 Check against member sex
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 17) || '5' || SUBSTR(err_code, 19)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 18, 1) = '0'
  AND   m_eff_date IS NOT NULL
  AND   adj_code = '201'
  AND   EXISTS (SELECT 1
                FROM MR_MEMBER b
       WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
                AND   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
       AND   b.sex = 'M')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  lv_valid_line := TRIM('18 OK');


     ------------------------------
  --19. Maternity Termination Date
  --    19.1 Check missing value
/*
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 18) || '1' || SUBSTR(err_code, 20)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 19, 1) = '0'
  AND   adj_code = '501'
  AND   m_term_date IS NULL;
*/

  --    19.3 Check clear field but not change optional benefit
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 18) || '3' || SUBSTR(err_code, 20)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 19, 1) = '0'
   AND   adj_code <> '501'
     AND   m_term_date = to_date('01010001','ddmmyyyy')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --    19.4 Check Forward and Back Date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 18) || '4' || SUBSTR(err_code, 20)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 19, 1) = '0'
  AND   adj_code = '501'
     AND   m_term_date <> to_date('01010001','ddmmyyyy')
  AND   m_term_date IS NOT NULL
  AND  (MONTHS_BETWEEN(m_term_date, ld_BatchRunDate) > li_ForwardDate
  OR    MONTHS_BETWEEN(ld_BatchRunDate, m_term_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  --    19.5 Check against member sex
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 18) || '5' || SUBSTR(err_code, 20)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 19, 1) = '0'
  AND   adj_code = '501'
  AND   m_term_date <> to_date('01010001','ddmmyyyy')
  AND   m_term_date IS NOT NULL
  AND   EXISTS (SELECT 1
                FROM MR_MEMBER b
       WHERE b.cont_no = MR_MBR_BAT_UPD.cont_no
                AND   b.mbr_no = MR_MBR_BAT_UPD.mbr_no
       AND   b.sex = 'M')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  lv_valid_line := TRIM('19 OK');


     ------------------------------
  --20. Hospital Cash Effective Date
  --    20.1 Check missing value
/*
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 19) || '1' || SUBSTR(err_code, 21)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 20, 1) = '0'
  AND   adj_code = '201'
  AND   w_eff_date IS NULL;
*/

  --    20.3 Check clear field but not change optional benefit
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 19) || '3' || SUBSTR(err_code, 21)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 20, 1) = '0'
  AND   adj_code <> '901'
  AND   w_eff_date = to_date('01010001','ddmmyyyy')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --    20.4 Check Forward and Back Date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 19) || '4' || SUBSTR(err_code, 21)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 20, 1) = '0'
  AND   adj_code in ('201','901')
  AND   w_eff_date <> to_date('01010001','ddmmyyyy')
  AND   w_eff_date IS NOT NULL
  AND  (MONTHS_BETWEEN(w_eff_date, ld_BatchRunDate) > li_ForwardDate
  OR    MONTHS_BETWEEN(ld_BatchRunDate, w_eff_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

 lv_valid_line := TRIM('20 OK');
     ------------------------------
  --21. Maternity Termination Date
  --    21.1 Check missing value
/*
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 20) || '1' || SUBSTR(err_code, 22)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 21, 1) = '0'
  AND   adj_code = '501'
  AND   w_term_date IS NULL;
*/

  --    21.3 Check clear field but not change optional benefit
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 20) || '3' || SUBSTR(err_code, 22)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 21, 1) = '0'
  AND   adj_code <> '501'
  AND   w_term_date = to_date('01010001','ddmmyyyy')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --    21.4 Check Forward and Back Date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 20) || '4' || SUBSTR(err_code, 22)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 21, 1) = '0'
  AND   adj_code = '501'
     AND   w_term_date <> to_date('01010001','ddmmyyyy')
  AND   w_term_date IS NOT NULL
  AND  (MONTHS_BETWEEN(w_term_date, ld_BatchRunDate) > li_ForwardDate
  OR    MONTHS_BETWEEN(ld_BatchRunDate, w_term_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13


  lv_valid_line := TRIM('21 OK');
     ------------------------------
  --22. Top Up Effective Date
  --    22.1 Check missing value
/*
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 21) || '1' || SUBSTR(err_code, 23)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 22, 1) = '0'
  AND   adj_code = '201'
  AND   t_eff_date IS NULL;
*/

  --    22.3 Check clear field but not change optional benefit
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 21) || '3' || SUBSTR(err_code, 23)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 22, 1) = '0'
  AND   adj_code <> '901'
  AND   t_eff_date = to_date('01010001','ddmmyyyy')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --    22.4 Check Forward and Back Date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 21) || '4' || SUBSTR(err_code, 23)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 22, 1) = '0'
  AND   adj_code in ('201','901')
  AND   t_eff_date <> to_date('01010001','ddmmyyyy')
  AND   t_eff_date IS NOT NULL
  AND  (MONTHS_BETWEEN(t_eff_date, ld_BatchRunDate) > li_ForwardDate
  OR    MONTHS_BETWEEN(ld_BatchRunDate, t_eff_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

 lv_valid_line := TRIM('22 OK');
     ------------------------------
  --23. Top Up Termination Date
  --    23.1 Check missing value
/*
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 22) || '1' || SUBSTR(err_code, 24)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 23, 1) = '0'
  AND   adj_code = '501'
  AND   t_term_date IS NULL;
*/

  --    23.3 Check clear field but not change optional benefit
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 22) || '3' || SUBSTR(err_code, 24)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 23, 1) = '0'
  AND   adj_code <> '501'
  AND   t_term_date = to_date('01010001','ddmmyyyy')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --    23.4 Check Forward and Back Date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 22) || '4' || SUBSTR(err_code, 24)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 23, 1) = '0'
  AND   adj_code = '501'
     AND   t_term_date <> to_date('01010001','ddmmyyyy')
  AND   t_term_date IS NOT NULL
  AND  (MONTHS_BETWEEN(t_term_date, ld_BatchRunDate) > li_ForwardDate
  OR    MONTHS_BETWEEN(ld_BatchRunDate, t_term_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  lv_valid_line := TRIM('23 OK');
     ------------------------------
  --24. Dental Effective Date
  --    24.1 Check missing value
/*
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 23) || '1' || SUBSTR(err_code, 25)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 24, 1) = '0'
  AND   adj_code = '201'
  AND   d_eff_date IS NULL;
*/

  --    24.3 Check clear field but not change optional benefit
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 23) || '3' || SUBSTR(err_code, 25)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 24, 1) = '0'
  AND   adj_code <> '901'
  AND   d_eff_date = to_date('01010001','ddmmyyyy')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --    24.4 Check Forward and Back Date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 23) || '4' || SUBSTR(err_code, 25)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 24, 1) = '0'
  AND   adj_code in ('201','901')
  AND   d_eff_date <> to_date('01010001','ddmmyyyy')
  AND   d_eff_date IS NOT NULL
  AND  (MONTHS_BETWEEN(d_eff_date, ld_BatchRunDate) > li_ForwardDate
  OR    MONTHS_BETWEEN(ld_BatchRunDate, d_eff_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  lv_valid_line := TRIM('24 OK');
     ------------------------------
  --25. Dental Termination Date
  --    25.1 Check missing value
/*
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 24) || '1' || SUBSTR(err_code, 26)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 25, 1) = '0'
  AND   adj_code = '501'
  AND   d_term_date IS NULL;
*/

  --    25.3 Check clear field but not change optional benefit
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 24) || '3' || SUBSTR(err_code, 26)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 25, 1) = '0'
  AND   adj_code <> '501'
  AND   d_term_date = to_date('01010001','ddmmyyyy')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --    25.4 Check Forward and Back Date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 24) || '4' || SUBSTR(err_code, 26)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 25, 1) = '0'
  AND   adj_code = '501'
     AND   d_term_date <> to_date('01010001','ddmmyyyy')
  AND   d_term_date IS NOT NULL
  AND  (MONTHS_BETWEEN(d_term_date, ld_BatchRunDate) > li_ForwardDate
  OR    MONTHS_BETWEEN(ld_BatchRunDate, d_term_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

  lv_valid_line := TRIM('25 OK');
     ------------------------------
  --26. Optical Effective Date
  --    26.1 Check missing value
/*
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 25) || '1' || SUBSTR(err_code, 27)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 26, 1) = '0'
  AND   adj_code = '201'
  AND   g_eff_date IS NULL;
*/

  --    26.3 Check clear field but not change optional benefit
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 25) || '3' || SUBSTR(err_code, 27)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 26, 1) = '0'
  AND   adj_code <> '901'
  AND   g_eff_date = to_date('01010001','ddmmyyyy')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --    26.4 Check Forward and Back Date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 25) || '4' || SUBSTR(err_code, 27)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 26, 1) = '0'
  AND   adj_code in ('201','901')
  AND   g_eff_date <> to_date('01010001','ddmmyyyy')
  AND   g_eff_date IS NOT NULL
  AND  (MONTHS_BETWEEN(g_eff_date, ld_BatchRunDate) > li_ForwardDate
  OR    MONTHS_BETWEEN(ld_BatchRunDate, g_eff_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13



 lv_valid_line := TRIM('26 OK');
     ------------------------------
  --27. Dental Termination Date
  --    27.1 Check missing value
/*
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 26) || '1' || SUBSTR(err_code, 28)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 27, 1) = '0'
  AND   adj_code = '501'
  AND   g_term_date IS NULL;
*/

  --    27.3 Check clear field but not change optional benefit
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 26) || '3' || SUBSTR(err_code, 28)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 27, 1) = '0'
  AND   adj_code <> '501'
  AND   g_term_date = to_date('01010001','ddmmyyyy')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --    27.4 Check Forward and Back Date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 26) || '4' || SUBSTR(err_code, 28)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 27, 1) = '0'
  AND   adj_code = '501'
     AND   g_term_date <> to_date('01010001','ddmmyyyy')
  AND   g_term_date IS NOT NULL
  AND  (MONTHS_BETWEEN(g_term_date, ld_BatchRunDate) > li_ForwardDate
  OR    MONTHS_BETWEEN(ld_BatchRunDate, g_term_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13


  lv_valid_line := TRIM('27 OK');
     ------------------------------
  --28. Evacuation Effective Date
  --    28.1 Check missing value
/*
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 27) || '1' || SUBSTR(err_code, 29)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 28, 1) = '0'
  AND   adj_code = '201'
  AND   e_eff_date IS NULL;
*/

  --    28.3 Check clear field but not change optional benefit
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 27) || '3' || SUBSTR(err_code, 29)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 28, 1) = '0'
  AND   adj_code <> '901'
  AND   e_eff_date = to_date('01010001','ddmmyyyy')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --    28.4 Check Forward and Back Date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 27) || '4' || SUBSTR(err_code, 29)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 28, 1) = '0'
  AND   adj_code in ('201','901')
  AND   e_eff_date <> to_date('01010001','ddmmyyyy')
  AND   e_eff_date IS NOT NULL
  AND  (MONTHS_BETWEEN(e_eff_date, ld_BatchRunDate) > li_ForwardDate
  OR    MONTHS_BETWEEN(ld_BatchRunDate, e_eff_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13


 lv_valid_line := TRIM('28 OK');
     ------------------------------
  --29. Evacuation Termination Date
  --    29.1 Check missing value
/*
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 28) || '1' || SUBSTR(err_code, 30)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 29, 1) = '0'
  AND   adj_code = '501'
  AND   e_term_date IS NULL;
*/

  --    29.3 Check clear field but not change optional benefit
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 28) || '3' || SUBSTR(err_code, 30)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 29, 1) = '0'
  AND   adj_code <> '501'
  AND   e_term_date = to_date('01010001','ddmmyyyy')
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

     --    29.4 Check Forward and Back Date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 28) || '4' || SUBSTR(err_code, 30)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 29, 1) = '0'
  AND   adj_code = '501'
     AND   e_term_date <> to_date('01010001','ddmmyyyy')
  AND   e_term_date IS NOT NULL
  AND  (MONTHS_BETWEEN(e_term_date, ld_BatchRunDate) > li_ForwardDate
  OR    MONTHS_BETWEEN(ld_BatchRunDate, e_term_date) > li_BackDate)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

    --30 Nationality
     --30.1Does not exist
--   UPDATE MR_MBR_BAT_UPDMBR_NAME
--   SET err_code = SUBSTR(err_code, 1, 29) || '4' || SUBSTR(err_code, 31)
--   WHERE SUBSTR(err_code, 1, 1) = '0'
--   AND   SUBSTR(err_code, 2, 1) = '0'
--   AND   SUBSTR(err_code, 3, 1) = '0'
--    AND   SUBSTR(err_code, 30, 1) = '0'
--   and   MR_MBR_BAT_UPD.CTRY_CODE not in ( select 1 from sy_sys_code where sys_type='COUNTRY_CODE' );
ln_check := -950;
  --30 Branch Code
  -- Missing
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 29) || '1' || SUBSTR(err_code, 31)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 30, 1) = '0'
  AND   BRANCH_CODE =  ''''''
  AND   exists (select 1 from MR_CUST_BRANCH b where MR_MBR_BAT_UPD.CONT_NO=b.CONT_NO)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

--2009-07-06 HoLaamC HotFix Branch Code is missing start
  -- Missing
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 29) || '1' || SUBSTR(err_code, 31)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 30, 1) = '0'
   AND adj_code = '702'
  AND   (BRANCH_CODE =  '''''' OR BRANCH_CODE is NULL)
  AND   exists (select 1 from MR_CUST_BRANCH b where MR_MBR_BAT_UPD.CONT_NO=b.CONT_NO)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
     AND   CRT_DATE=pc_crt_date;
--2009-07-06 HoLaamC HotFix Branch Code is missing end

ln_check := -951;
 -- invalid value
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 29) || '2' || SUBSTR(err_code, 31)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 30, 1) = '0'
  AND NOT BRANCH_CODE IS NULL
  AND trim(branch_code) not in (select trim(branch_code) from MR_CUST_BRANCH b where MR_MBR_BAT_UPD.CONT_NO=b.CONT_NO)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

ln_check := -952;
    -- Branch cannot be same as the orginal member branch code
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 29) || '4' || SUBSTR(err_code, 31)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 30, 1) = '0'
  AND NOT BRANCH_CODE IS NULL
  AND trim(branch_code) in (select trim(branch_code) from MR_MEMBER b where MR_MBR_BAT_UPD.CONT_NO=b.CONT_NO and MR_MBR_BAT_UPD.MBR_NO = b.MBR_NO)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

--HotFix Branch Code 2009-01-19 HoLaam start
         --Branch Code is not Valid
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 29) || '7' || SUBSTR(err_code, 31)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
  AND   SUBSTR(err_code, 30, 1) = '0'
  AND NOT BRANCH_CODE IS NULL
  AND trim(branch_code) not in (select trim(branch_code) from MR_CUST_BRANCH b where MR_MBR_BAT_UPD.CONT_NO=b.CONT_NO AND b.VALID = 'Y')
  AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
  AND   CRT_DATE=pc_crt_date;
ln_check := -952.5;
--HotFix Branch Code 2009-01-19 HoLaam start

ln_check := -953;
 --Too long
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 29) || '9' || SUBSTR(err_code, 31)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND length(trim(BRANCH_CODE))>10
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13

ln_check := -954;
     -- Both Branch Code & Cont Year Month must co-exist
/* 2006-10-13 START, no cont_yymm for changeb branch
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 29) || '8' || SUBSTR(err_code, 31)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND ((branch_code is null and not cont_yymm is null)
     or (not branch_code is null and cont_yymm is null));
*/
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 29) || '8' || SUBSTR(err_code, 31)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND adj_code <> '702'
  AND ((branch_code is null and not cont_yymm is null)
     or (not branch_code is null and cont_yymm is null))
  AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
  AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
-- 2006-10-13 END
ln_check := -955;
 --31 Branch Contract Year & Month
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 101) || '1' || SUBSTR(err_code, 103)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 102, 1) = '0'
     AND   NOT trim(cont_yymm) = '''''' and NOT trim(cont_yymm) is null
  AND NOT EXISTS(select 1 from mr_contract a where a.CONT_NO=MR_MBR_BAT_UPD.CONT_NO
                                                               and a.CONT_YYMM=MR_MBR_BAT_UPD.CONT_YYMM)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
-- 2006-10-13 END
                  --and b.MBR_NO=a.);
ln_check := -956;                  --and a.MBR_NO=b.
 --Too long
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 101) || '9' || SUBSTR(err_code, 103)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND length(trim(CONT_YYMM))>6
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
ln_check := -957;
     -- Check current branch effective date must be greater than the previous branch effective date
     UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 101) || '8' || SUBSTR(err_code, 103)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
     AND   SUBSTR(err_code, 30, 1) = '0'
     AND   SUBSTR(err_code, 102, 1) = '0'
     AND   CONT_YYMM is not null
     AND   (select a.branch_eff_date from mr_member a
                   where a.cont_no = MR_MBR_BAT_UPD.cont_no
                   and     a.mbr_no = MR_MBR_BAT_UPD.mbr_no)
                   >=
                    to_date( to_char((select eff_date
                                      from mr_contract b
                                      where b.cont_no = MR_MBR_BAT_UPD.cont_no
                                      and b.cont_yymm = MR_MBR_BAT_UPD.CONT_YYMM), 'DD')
                                     || '/' ||
                                      substr(MR_MBR_BAT_UPD.CONT_YYMM, 5, 2)
                                     || '/' ||
                                      substr(MR_MBR_BAT_UPD.CONT_YYMM, 1, 4), 'DD/MM/YYYY' )
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
ln_check := -960;
 --32 Card Received Date
   --32.1 invalid received date
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 102) || '3' || SUBSTR(err_code, 104)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 103, 1) = '0'
  AND   CARD_RECEIVE_DATE IS NOT NULL
  AND NOT EXISTS(SELECT 1 FROM mr_member A WHERE a.CONT_NO=MR_MBR_BAT_UPD.CONT_NO
                                                               AND a.MBR_NO=MR_MBR_BAT_UPD.MBR_NO
                  AND MR_MBR_BAT_UPD.CARD_RECEIVE_DATE >=a.REG_DATE)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
                  --AND MR_MBR_BAT_UPD.CARD_RECEIVE_DATE<=nvl(A.TERM_DATE,MR_MBR_BAT_UPD.CARD_RECEIVE_DATE)
                   --AND a.ID_CARD_NO=MR_MBR_BAT_UPD.ID_CARD_NO );
-- Added by Tommy on 20041021
 IF UPPER(ls_return_value)='BME' then
  UPDATE MR_MBR_BAT_UPD
  SET err_code = SUBSTR(err_code, 1, 102) || '2' || SUBSTR(err_code, 104)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
   AND   SUBSTR(err_code, 103, 1) = '0'
  AND    CARD_RECEIVE_DATE IS NOT NULL
     AND EXISTS(SELECT 1 FROM mr_member A WHERE a.CONT_NO=MR_MBR_BAT_UPD.CONT_NO
                                                               AND a.MBR_NO=MR_MBR_BAT_UPD.MBR_NO
                  AND A.TERM_DATE IS NULL)
     AND   TRIM(CRT_USER)=TRIM(pc_crt_user)   -- 2006-10-13
     AND   CRT_DATE=pc_crt_date;               -- 2006-10-13
--  AND  ( (
--          CARD_RECEIVE_DATE IS NOT NULL
--             AND NOT EXISTS(SELECT 1 FROM mr_member A WHERE a.CONT_NO=MR_MBR_BAT_UPD.CONT_NO
--                                                                AND a.MBR_NO=MR_MBR_BAT_UPD.MBR_NO
--                   AND A.TERM_DATE IS NULL
--                    AND a.ID_CARD_NO=MR_MBR_BAT_UPD.ID_CARD_NO )) OR
--   (CARD_RECEIVE_DATE IS  NULL
--      AND NOT EXISTS(SELECT 1 FROM mr_member A WHERE a. CONT_NO=MR_MBR_BAT_UPD.CONT_NO
--                                                                AND a.MBR_NO=MR_MBR_BAT_UPD.MBR_NO
--                   AND A.TERM_DATE IS NOT NULL
--                    AND a.ID_CARD_NO=MR_MBR_BAT_UPD.ID_CARD_NO )));

-- 2008-01-31 REF-0522, START
  UPDATE MR_MBR_BAT_UPD u
  SET err_code = SUBSTR(err_code, 1, 45) || '2' || SUBSTR(err_code, 47)
  WHERE SUBSTR(err_code, 1, 1) = '0'
  AND   SUBSTR(err_code, 2, 1) = '0'
  AND   SUBSTR(err_code, 3, 1) = '0'
  AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
  AND   CRT_DATE=pc_crt_date
  AND   adj_code = '401'     -- terminate/reinstate member
  AND   NOT EXISTS(SELECT 1 FROM MR_CONTRACT c
    WHERE c.CONT_NO = RTRIM(u.CONT_NO)
    --2013-12-20 revise: AND c.EFF_DATE <= TRUNC(SYSDATE) AND TRUNC(SYSDATE) <= c.TERM_DATE
    AND c.CONT_YYMM = MRUPDMBAT01_chk_cont_period(RTRIM(u.CONT_NO), u.MBR_TERM_DATE));
-- 2008-01-31 REF-0522, END

-- 2006-10-13, START
ln_check := -961;
   -- 110: Branch Effective Date

   -- 1. invalid branch effective date
   -- 2. branch effective date is empty
   -- 3. branch effective date must be greater than member effective date
   -- 4. new branch effective date must be greater than old branch effective dat
   -- 5. branch effective date does not allow back date for more than 12 months.
   -- 6. branch effective date does not allow forward date for more than 3 months
   -- 7. No contract found with the new Branch Effective Date.
   -- 8. Branch effective date must be less than terminaton date
   -- 9. Cannot Change branch with incurred claim record(s)
   -- E. Cannot perform branch change more than once per day
   -- M. Only Applicant or Employee can perform branch change
   IF UPPER(ls_return_value) = 'BME' THEN
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 109) || '2' || SUBSTR(err_code, 111)
         WHERE SUBSTR(err_code, 1, 1) = '0' -- adj_code
           AND SUBSTR(err_code, 3, 1) = '0' -- mbrshp_no
           AND adj_code = '702'
           AND branch_eff_date IS NULL
           AND adj_code = '702'
           AND TRIM(CRT_USER)=TRIM(pc_crt_user)
           AND CRT_DATE=pc_crt_date;

      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 109) || '3' || SUBSTR(err_code, 111)
         WHERE SUBSTR(err_code, 1, 1) = '0' -- adj_code
           AND SUBSTR(err_code, 3, 1) = '0' -- mbrshp_no
           AND branch_eff_date IS NOT NULL
           AND adj_code = '702'
           AND EXISTS(SELECT 1 FROM mr_member a
                         WHERE a.cont_no = MR_MBR_BAT_UPD.cont_no
                           AND a.mbrshp_no = MR_MBR_BAT_UPD.mbrshp_no
                           AND a.eff_date >= MR_MBR_BAT_UPD.branch_eff_date)
           AND TRIM(CRT_USER)=TRIM(pc_crt_user)
           AND CRT_DATE=pc_crt_date;

      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 109) || '4' || SUBSTR(err_code, 111)
         WHERE SUBSTR(err_code, 1, 1) = '0' -- adj_code
           AND SUBSTR(err_code, 3, 1) = '0' -- mbrshp_no
           AND branch_eff_date IS NOT NULL
           AND adj_code = '702'
           AND EXISTS(SELECT 1 FROM mr_member a
                         WHERE a.cont_no = MR_MBR_BAT_UPD.cont_no
                           AND a.mbrshp_no = MR_MBR_BAT_UPD.mbrshp_no
                           AND a.branch_eff_date >= MR_MBR_BAT_UPD.branch_eff_date)
           AND TRIM(CRT_USER)=TRIM(pc_crt_user)
           AND CRT_DATE=pc_crt_date;

      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 109) || 'M' || SUBSTR(err_code, 111)
         WHERE SUBSTR(err_code, 1, 1) = '0' -- adj_code
           AND SUBSTR(err_code, 3, 1) = '0' -- mbrshp_no
           AND branch_eff_date IS NOT NULL
           AND adj_code = '702'
           AND NOT EXISTS(SELECT 1 FROM mr_member a
                           WHERE a.cont_no = MR_MBR_BAT_UPD.cont_no
                             AND a.mbrshp_no = MR_MBR_BAT_UPD.mbrshp_no
                             --2017-05-08 REF-2537 Prod Log JimmyC Start
                             --AND a.mbr_type IN ('M', 'E'))
                             AND MR_BAT_PKG.GET_MBR_TYPE_GRP(a.mbr_type) = 'E')
                             --2017-05-08 REF-2537 Prod Log JimmyC End
           AND TRIM(CRT_USER)=TRIM(pc_crt_user)
           AND CRT_DATE=pc_crt_date;

   -- 111: Replace Issue Card

   -- 1. card reprint reason not specified
   -- 2. card reprint reason too long
   -- 3. unknown card reprint reason
   -- 4. no current contract found
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 110) || '3' || SUBSTR(err_code, 112)
         WHERE SUBSTR(err_code, 1, 1) = '0' -- adj_code
           AND SUBSTR(err_code, 3, 1) = '0' -- mbrshp_no
           AND adj_code = '703'
           AND card_reprint_reason IS NOT NULL
           AND NOT EXISTS(SELECT 1 FROM SY_SYS_CODE c
                             WHERE c.sys_type = 'CARD_REASON'
                               AND TRIM(c.sys_code) = TRIM(card_reprint_reason))
           AND TRIM(CRT_USER)=TRIM(pc_crt_user)
           AND CRT_DATE=pc_crt_date;

      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 110) || '2' || SUBSTR(err_code, 112)
         WHERE SUBSTR(err_code, 1, 1) = '0' -- adj_code
           AND SUBSTR(err_code, 3, 1) = '0' -- mbrshp_no
           AND adj_code = '703'
           AND card_reprint_reason IS NOT NULL
           AND LENGTH(TRIM(card_reprint_reason)) > 1
           AND TRIM(CRT_USER)=TRIM(pc_crt_user)
           AND CRT_DATE=pc_crt_date;

      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 110) || '1' || SUBSTR(err_code, 112)
         WHERE SUBSTR(err_code, 1, 1) = '0' -- adj_code
           AND SUBSTR(err_code, 3, 1) = '0' -- mbrshp_no
           AND adj_code = '703'
           AND card_reprint_reason IS NULL
           AND TRIM(CRT_USER)=TRIM(pc_crt_user)
           AND CRT_DATE=pc_crt_date;
   END IF;
-- 2006-10-13, END

-- 2007-07-05, START
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 5) || '7' || SUBSTR(err_code, 7)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 2, 1) = '0'
       AND SUBSTR(err_code, 3, 1) = '0'
       AND TRIM(adj_code) = '401'
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date
       AND EXISTS (SELECT 1
                      FROM MR_MBR_BAT_UPD b1, MR_MEMBER m1
                      WHERE TRIM(b1.CRT_USER)=TRIM(pc_crt_user)
                        AND b1.CRT_DATE=pc_crt_date
                        AND TRIM(b1.CONT_NO) = m1.CONT_NO
                        AND TRIM(b1.MBR_NO) = m1.MBR_NO
                        --AND m1.MBR_TYPE IN ('A', 'E') --2013-03-26 REF-1206 CR137 RichardL
                        AND MR_BAT_PKG.GET_MBR_TYPE_GRP(m1.MBR_TYPE) = 'E' --2013-03-26 REF-1206 CR137 RichardL
                        AND m1.STATUS = 'A'
                        AND TRIM(b1.CONT_NO) = TRIM(MR_MBR_BAT_UPD.CONT_NO)
                        AND SUBSTR(TRIM(b1.MBR_NO), 1, 5) = SUBSTR(TRIM(MR_MBR_BAT_UPD.MBR_NO), 1, 5)
                        AND TRIM(b1.ADJ_CODE) = TRIM(MR_MBR_BAT_UPD.ADJ_CODE))
       AND EXISTS (SELECT 1
                      FROM MR_MBR_BAT_UPD b2, MR_MEMBER m2
                      WHERE TRIM(b2.CRT_USER)=TRIM(pc_crt_user)
                        AND b2.CRT_DATE=pc_crt_date
                        AND TRIM(b2.CONT_NO) = m2.CONT_NO
                        AND TRIM(b2.MBR_NO) = m2.MBR_NO
                        AND m2.MBR_TYPE NOT IN ('A', 'E') --2013-03-26 REF-1206 CR137 RichardL
                        AND MR_BAT_PKG.GET_MBR_TYPE_GRP(m2.MBR_TYPE) <> 'E' --2013-03-26 REF-1206 CR137 RichardL
                        AND m2.STATUS = 'A'
                        AND TRIM(b2.CONT_NO) = TRIM(MR_MBR_BAT_UPD.CONT_NO)
                        AND SUBSTR(TRIM(b2.MBR_NO), 1, 5) = SUBSTR(TRIM(MR_MBR_BAT_UPD.MBR_NO), 1, 5)
                        AND TRIM(b2.ADJ_CODE) = TRIM(MR_MBR_BAT_UPD.ADJ_CODE));
-- 2007-07-05, END
END IF ;

 lv_valid_line := TRIM('29 OK');

-- 2007-07-19 REF-0474, START
  -- error 112 - member mobile no
  -- 1. length of mobile no should more than 10
  -- 2. mobile no not begin with 05
  -- 3. mobile no accept digits only
  -- 4. length of mobile no > 20
  -- 5. mobile no. cannot be empty --2014-04-24 REF-1454 CR211 Nathan
  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 111) || '1' || SUBSTR(err_code, 113)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 112, 1) = '0'
       AND mbr_mobile_no IS NOT NULL
       AND mbr_mobile_no <> ''''''
       AND LENGTH(TRIM(mbr_mobile_no)) < 10
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;

  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 111) || '2' || SUBSTR(err_code, 113)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 112, 1) = '0'
       AND mbr_mobile_no IS NOT NULL
       AND mbr_mobile_no <> ''''''
       AND SUBSTR(TRIM(mbr_mobile_no) || '  ', 1, 2) <> '05'
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;

  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 111) || '3' || SUBSTR(err_code, 113)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 112, 1) = '0'
       AND mbr_mobile_no IS NOT NULL
       AND mbr_mobile_no <> ''''''
       AND Sy_Lib_Pkg.ChkNum(TRIM(mbr_mobile_no)) <> 0
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;

  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 111) || '4' || SUBSTR(err_code, 113)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 112, 1) = '0'
       AND mbr_mobile_no IS NOT NULL
       AND mbr_mobile_no <> ''''''
       AND LENGTH(TRIM(mbr_mobile_no)) > 20
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
       
  --2014-04-24 REF-1454 CR211 Nathan Start
  /*UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 111) || '5' || SUBSTR(err_code, 113)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 112, 1) = '0'
       AND mbr_mobile_no IS NULL OR TRIM(mbr_mobile_no) = ''''''
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;*/
  --2014-04-24 REF-1454 CR211 Nathan End

  -- error 113 - Communication preferred in Arabic
  -- 1. length of communication preferred is not equal to 1
  -- 2. communication preferred accept Y/N only

  --2011-05-04 REF-0819 Vicker, Start
/*  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 112) || '1' || SUBSTR(err_code, 114)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 113, 1) = '0'
       AND sms_pref_lang IS NOT NULL
       AND sms_pref_lang <> ''''''
       AND LENGTH(TRIM(sms_pref_lang)) <> 1
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;

  UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 112) || '2' || SUBSTR(err_code, 114)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 113, 1) = '0'
       AND sms_pref_lang IS NOT NULL
       AND sms_pref_lang <> ''''''
       AND UPPER(TRIM(sms_pref_lang)) NOT IN ('Y', 'N')
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
*/
-- 2007-07-19 REF-0474, END

    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 112) || '1' || SUBSTR(err_code, 114)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 113, 1) = '0'
       AND sms_pref_lang2 IS NOT NULL
       AND sms_pref_lang2 <> ''''''
       AND LENGTH(TRIM(sms_pref_lang2)) <> 2
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;

    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 112) || '2' || SUBSTR(err_code, 114)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 113, 1) = '0'
       AND sms_pref_lang2 IS NOT NULL
       AND sms_pref_lang2 <> ''''''
       AND UPPER(TRIM(sms_pref_lang2)) NOT IN ('11', '22', '33','44')
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;

   UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 112) || '3' || SUBSTR(err_code, 114)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 113, 1) = '1'
       AND SMS_IND IS NOT NULL
       AND SMS_IND <> ''''''
       AND LENGTH(TRIM(SMS_IND)) <> 1
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;

    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 112) || '4' || SUBSTR(err_code, 114)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 113, 1) = '1'
       AND SMS_IND IS NOT NULL
       AND SMS_IND <> ''''''
       AND UPPER(TRIM(SMS_IND)) NOT IN ('Y', 'N')
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;

     UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 112) || '5' || SUBSTR(err_code, 114)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 113, 1) = '2'
       AND SMS_IND IS NOT NULL
       AND SMS_IND <> ''''''
       AND LENGTH(TRIM(SMS_IND)) <> 1
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;

    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 112) || '6' || SUBSTR(err_code, 114)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 113, 1) = '2'
       AND SMS_IND IS NOT NULL
       AND SMS_IND <> ''''''
       AND UPPER(TRIM(SMS_IND)) NOT IN ('Y', 'N')
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;

   UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 112) || '7' || SUBSTR(err_code, 114)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 113, 1) = '0'
       AND SMS_IND IS NOT NULL
       AND SMS_IND <> ''''''
       AND LENGTH(TRIM(SMS_IND)) <> 1
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;

    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 112) || '8' || SUBSTR(err_code, 114)
     WHERE SUBSTR(err_code, 1, 1) = '0' -- contract no validation OK
       AND SUBSTR(err_code, 113, 1) = '0'
       AND SMS_IND IS NOT NULL
       AND SMS_IND <> ''''''
       AND UPPER(TRIM(SMS_IND)) NOT IN ('Y', 'N')
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
  --2011-05-04 REF-0819 Vicker, End

--2008-10-09 Ho Laam Chan REF-0564 CR050 START
--BI NO
--Check numeric
       /* UPDATE MR_MBR_BAT_UPD
               SET err_code = SUBSTR(err_code, 1, 113) || '1' || SUBSTR(err_code, 115)
               WHERE SUBSTR(err_code, 1, 1) = '0'
               AND SUBSTR(err_code, 114, 1) = '0'
               AND TRIM(adj_code) = '000'
               AND   trim(bi_no) is not null
               AND   sy_lib_pkg.chknum(trim(bi_no)) = -1
               AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
               AND   CRT_DATE=pc_crt_date;*/

--Too long
          UPDATE MR_MBR_BAT_UPD
                 SET err_code = SUBSTR(err_code, 1, 113) || '9' || SUBSTR(err_code, 115)
                 WHERE SUBSTR(err_code, 1, 1) = '0'
                 AND SUBSTR(err_code, 114, 1) = '0'
                 AND TRIM(adj_code) = '000'
                 AND   trim(bi_no) is not null
                 AND   length(trim(bi_no))>20
                 AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
                 AND   CRT_DATE=pc_crt_date;

--Check duplicate
        UPDATE MR_MBR_BAT_UPD a
               SET a.err_code = SUBSTR(a.err_code, 1, 113) || '7' || SUBSTR(a.err_code, 115)
               WHERE SUBSTR(err_code, 1, 1) = '0'
               AND SUBSTR(err_code, 114, 1) = '0'
               AND TRIM(adj_code) = '000'
               AND TRIM(a.bi_no) is not null
               AND EXISTS(SELECT 1 FROM (select bi_no from mr_mrupdmbat01_wrk
                   where TRIM(CRT_USER)=TRIM(pc_crt_user) and CRT_DATE=pc_crt_date
                   group by bi_no having count(1)>1) b
                   where a.bi_no=b.bi_no)
               --2009-07-31 LaamC CR076 REF-0608 start
               AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
               AND   CRT_DATE=pc_crt_date;
               --2009-07-31 LaamC CR076 REF-0608 end;

--Check duplicate
--2009-09-01 REF-0608 CR076 start
--        UPDATE MR_MBR_BAT_UPD a
--               SET a.err_code = SUBSTR(a.err_code, 1, 113) || '7' || SUBSTR(a.err_code, 115)
--               WHERE SUBSTR(err_code, 1, 1) = '0'
--               AND SUBSTR(err_code, 114, 1) = '0'
--               AND TRIM(adj_code) = '000'
--               AND TRIM(a.bi_no) is not null
--               AND EXISTS(SELECT 1 FROM (select bi_no from MR_MEMBER
--                   WHERE BI_NO IS NOT NULL --2009-08-03 LaamC CR076 REF-0608
--                   group by bi_no having count(1)>=1) b
--                   where  a.bi_no=b.bi_no)
--               --2009-07-31 LaamC CR076 REF-0608 start
--               AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
--               AND   CRT_DATE=pc_crt_date;
--            --2009-07-31 LaamC CR076 REF-0608 end;
            UPDATE MR_MBR_BAT_UPD a
            SET a.err_code = SUBSTR(a.err_code, 1, 113) || '7' || SUBSTR(a.err_code, 115)
            WHERE SUBSTR(err_code, 1, 1) = '0'
            AND SUBSTR(err_code, 114, 1) = '0'
            AND TRIM(adj_code) = '000'
            AND trim(a.bi_no) is not null
            AND a.bi_no in (select bi_no from mr_member
                        where  bi_no is not null
                        and status = 'A'
                        and bi_no in (select bi_no from MR_MBR_BAT_UPD
                                        where bi_no is not null
                                        AND TRIM(CRT_USER)=TRIM(pc_crt_user)
                                        AND CRT_DATE=pc_crt_date)
                        )
            AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
            AND   CRT_DATE=pc_crt_date;
--2009-09-01 REF-0608 CR076 end
--CARD PRINT
--Outside CARD PRINT Ind
        UPDATE MR_MBR_BAT_UPD
               SET err_code = SUBSTR(err_code, 1, 114) || '1'|| SUBSTR(err_code, 116)
               WHERE SUBSTR(err_code, 1, 1) = '0'
               AND SUBSTR(err_code, 115, 1) = '0'
               AND TRIM(adj_code) = '000'
             AND TRIM(CARD_PRINT) is not null
               AND   trim(CARD_PRINT) NOT IN ('N','Y')
               AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
               AND   CRT_DATE=pc_crt_date;
--Too long
        UPDATE MR_MBR_BAT_UPD
               SET err_code = SUBSTR(err_code, 1, 114) || '2'|| SUBSTR(err_code, 116)
               WHERE SUBSTR(err_code, 1, 1) = '0'
               AND SUBSTR(err_code, 115, 1) = '0'
               AND TRIM(adj_code) = '000'
               AND TRIM(CARD_PRINT) is not null
               AND LENGTH(TRIM(CARD_PRINT)) <> 1
               AND TRIM(CRT_USER)=TRIM(pc_crt_user)
               AND CRT_DATE=pc_crt_date;

--2008-10-09 Ho Laam Chan REF-0564 CR050 END
--2008-10-27 Ho Laam REF-0564 CR050 Start
--CLM_SWIFT_CODE
--if pay method is AT , the swift code must be input data
         UPDATE MR_MBR_BAT_UPD
                SET err_code = SUBSTR(err_code,1,115) || '1' || SUBSTR(err_code,117)
                WHERE SUBSTR(err_code,1, 1) = '0'
                AND SUBSTR(err_code,116, 1) = '0'
                AND UPPER(TRIM(CLM_PAY_METHOD)) = 'AT'
                AND (iban is not null or clm_branch_name is not null)  --2010-01-04 Raymond CR080 fix
                AND TRIM(NVL(CLM_SWIFT_CODE,'')||'-') = '-'
                AND TRIM(CRT_USER) = TRIM(pc_crt_user)
                AND CRT_DATE = pc_crt_date
                AND TRIM(adj_code) = '000';

--Outside Swift code
        UPDATE MR_MBR_BAT_UPD
               SET err_code = SUBSTR(err_code,1,115) || '2' || SUBSTR(err_code,117)
               WHERE SUBSTR(err_code,1, 1) = '0'
               AND SUBSTR(err_code,116, 1) = '0'
               AND TRIM(CLM_SWIFT_CODE) is not null
               AND NOT UPPER(TRIM(CLM_SWIFT_CODE)) IN (SELECT TRIM(SYS_CODE) FROM sy_sys_code WHERE UPPER(sys_type) = UPPER('BANK_SWIFT_CODE'))
               AND TRIM(CRT_USER) = TRIM(pc_crt_user)
               AND CRT_DATE = pc_crt_date
               AND TRIM(adj_code) = '000';

--CLM_BRANCH_NAME
--if pay method is AT , the CLM BRANCH NAME must be input data
       --2010-01-04 Raymond CR080 fix
         UPDATE MR_MBR_BAT_UPD
                SET err_code = SUBSTR(err_code,1,116) || '1' || SUBSTR(err_code,118)
                WHERE SUBSTR(err_code,1, 1) = '0'
                AND SUBSTR(err_code,117, 1) = '0'
                AND UPPER(TRIM(CLM_PAY_METHOD)) = 'AT'
                AND (trim(clm_swift_code) is not null or iban is not null)
                AND TRIM(NVL(CLM_BRANCH_NAME,'')||'-') = '-'
                AND TRIM(CRT_USER) = TRIM(pc_crt_user)
                AND CRT_DATE = pc_crt_date
                AND TRIM(adj_code) = '000';
         --2010-01-04 end

--length
         UPDATE MR_MBR_BAT_UPD
                SET err_code = SUBSTR(err_code,1,116) || '2' || SUBSTR(err_code,118)
                WHERE SUBSTR(err_code,1, 1) = '0'
                AND SUBSTR(err_code,117, 1) = '0'
                AND TRIM(CLM_BRANCH_NAME) is not NULL
                AND LENGTH(TRIM(CLM_BRANCH_NAME)) > 40
                AND TRIM(CRT_USER) = TRIM(pc_crt_user)
                AND CRT_DATE = pc_crt_date
                AND TRIM(adj_code) = '000';

--CLM_BRANCH_CODE
--if pay method is AT , the CLM BRANCH CODE must be input data
       /*  UPDATE MR_MBR_BAT_UPD
                SET err_code = SUBSTR(err_code,1,117) || '1' || SUBSTR(err_code,119)
                WHERE SUBSTR(err_code,1, 1) = '0'
                AND SUBSTR(err_code,118, 1) = '0'
                AND UPPER(TRIM(CLM_PAY_METHOD)) = 'AT'
                AND TRIM(NVL(CLM_BRANCH_CODE,'')||'-') = '-'
                AND TRIM(CRT_USER) = TRIM(pc_crt_user)
                AND CRT_DATE = pc_crt_date
                AND TRIM(adj_code) = '000'; */

         UPDATE MR_MBR_BAT_UPD
                SET err_code = SUBSTR(err_code,1,117) || '2' || SUBSTR(err_code,119)
                WHERE SUBSTR(err_code,1, 1) = '0'
                AND SUBSTR(err_code,118, 1) = '0'
                AND TRIM(CLM_BRANCH_CODE) is not null
                AND LENGTH(TRIM(CLM_BRANCH_CODE)) > 6
                AND TRIM(CRT_USER) = TRIM(pc_crt_user)
                AND CRT_DATE = pc_crt_date
                AND TRIM(adj_code) = '000';

        UPDATE MR_MBR_BAT_UPD
               SET err_code = SUBSTR(err_code, 1, 117) || '3' || SUBSTR(err_code, 119)
               WHERE SUBSTR(err_code, 1, 1) = '0'
               AND SUBSTR(err_code, 118, 1) = '0'
               AND TRIM(adj_code) = '000'
               AND   trim(CLM_BRANCH_CODE) is not null
               AND   sy_lib_pkg.chknum(trim(CLM_BRANCH_CODE)) = -1
               AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
               AND   CRT_DATE=pc_crt_date;
        --2009-03-19 Ho Laam REF0591 start
        --Pay Account Name
        UPDATE MR_MBR_BAT_UPD
               SET err_code = SUBSTR(err_code, 1, 118) || '1' || SUBSTR(err_code, 120)
               WHERE SUBSTR(err_code, 1, 1) = '0'
               AND SUBSTR(err_code, 119, 1) = '0'
               AND TRIM(adj_code) = '000'
               AND   trim(BANK_NAME) is not null
               AND   LENGTH(TRIM(BANK_NAME)) > 40
               AND   TRIM(CRT_USER)=TRIM(pc_crt_user)
               AND   CRT_DATE=pc_crt_date;
       --2009-03-19 Ho Laam REF0591 end

       --2009-07-22 HoLaamC CR076 REF-0608 start
       UPDATE MR_MBR_BAT_UPD
            --SET err_code = SUBSTR(err_code, 1 ,119) || '1'
            SET err_code = SUBSTR(err_code, 1 ,119) || '1' || SUBSTR(err_code, 121) --2011-09-12 REF-0902 Shaman
            WHERE SUBSTR(err_code,1,1) = '0'
            AND cont_no is not NULL
            AND MR_SCR_CUSTMNT_PKG.Check_Cont_Susp(TRIM(cont_no)) = 'Y'
            AND TRIM(adj_code) in ('601','701','702','703')
            AND TRIM(CRT_USER)=TRIM(pc_crt_user)
            AND CRT_DATE=pc_crt_date;

       UPDATE MR_MBR_BAT_UPD
            --SET err_code = SUBSTR(err_code, 1 ,119) || '1'
            SET err_code = SUBSTR(err_code, 1 ,119) || '1' || SUBSTR(err_code, 121) --2011-09-12 REF-0902 Shaman
            WHERE SUBSTR(err_code,1,1) = '0'
            AND cont_no is not NULL
            AND MR_SCR_CUSTMNT_PKG.Check_Cont_Susp(TRIM(cont_no)) = 'Y'
            AND mbr_term_date IS NOT NULL
            AND TRIM(adj_code) in ('401')
            AND TRIM(CRT_USER)=TRIM(pc_crt_user)
            AND CRT_DATE=pc_crt_date;
       --2009-07-22 HoLaamC CR076 REF-0608 end

       --2011-09-12 REF-0902 Shaman Start
       --VIP Code
       --1.Does not exist
       UPDATE MR_MBR_BAT_UPD
            SET err_code = SUBSTR(err_code, 1 ,120) || '1' || SUBSTR(err_code, 122)
            WHERE SUBSTR(err_code,1,1) = '0'
            AND not (TRIM(VIP_CODE) = 'VP' or trim(vip_code) is null)
            and trim(vip_code) <> ''''''
            AND TRIM(adj_code) in ('000')
            AND TRIM(CRT_USER)=TRIM(pc_crt_user)
            AND CRT_DATE=pc_crt_date;
       --CCHI status
       --1.Does not exist
       UPDATE MR_MBR_BAT_UPD
            SET err_code = SUBSTR(err_code, 1 ,121) || '1' || SUBSTR(err_code, 123)
            WHERE SUBSTR(err_code,1,1) = '0'
            AND NOT trim(cchi_status) IS NULL
            AND NOT trim(cchi_status) IN (SELECT trim(cast(sys_code as varchar(200))) FROM sy_sys_code where sys_type = 'STATUS_CCHI')
            and trim(cchi_status) <> ''''''
            AND TRIM(adj_code) in ('000')
            AND TRIM(CRT_USER)=TRIM(pc_crt_user)
            AND CRT_DATE=pc_crt_date;
       --CCHI reject reason
       --1.Does not exist
       --2.Have reject reason with status approved
       --3.Reject reason is missing with Status is rejected
       UPDATE MR_MBR_BAT_UPD
            --SET err_code = SUBSTR(err_code, 1 ,122) || '1' --2013-06-26 REF-1279 CR187 RichardL
            SET err_code = SUBSTR(err_code, 1 ,122) || '1' || SUBSTR(err_code, 124) --2013-06-26 REF-1279 CR187 RichardL
            WHERE SUBSTR(err_code,1,1) = '0'
            AND NOT trim(cchi_rej_reason) IS NULL
            AND NOT trim(cchi_rej_reason) IN (SELECT trim(cast(sys_code as varchar(200))) FROM sy_sys_code where sys_type = 'CCHI_REJ_REASON')
            and trim(cchi_rej_reason) <> ''''''
            AND TRIM(adj_code) in ('000')
            AND TRIM(CRT_USER)=TRIM(pc_crt_user)
            AND CRT_DATE=pc_crt_date;

       UPDATE MR_MBR_BAT_UPD
            --SET err_code = SUBSTR(err_code, 1 ,122) || '2' --2013-06-26 REF-1279 CR187 RichardL
            SET err_code = SUBSTR(err_code, 1 ,122) || '2' || SUBSTR(err_code, 124) --2013-06-26 REF-1279 CR187 RichardL
            WHERE SUBSTR(err_code,1,1) = '0'
            AND NOT trim(cchi_rej_reason) IS NULL
            --AND NOT trim(cchi_rej_reason) IN (SELECT trim(cast(sys_code as varchar(200))) FROM sy_sys_code where sys_type = 'CCHI_REJ_REASON')
            and trim(cchi_rej_reason) <> ''''''
            and trim(cchi_status) = 'A'
            AND TRIM(adj_code) in ('000')
            AND TRIM(CRT_USER)=TRIM(pc_crt_user)
            AND CRT_DATE=pc_crt_date;

       UPDATE MR_MBR_BAT_UPD
            --SET err_code = SUBSTR(err_code, 1 ,122) || '3' --2013-06-26 REF-1279 CR187 RichardL
            SET err_code = SUBSTR(err_code, 1 ,122) || '3' || SUBSTR(err_code, 124) --2013-06-26 REF-1279 CR187 RichardL
            WHERE SUBSTR(err_code,1,1) = '0'
            AND (trim(cchi_rej_reason) = '' or trim(cchi_rej_reason) IS NULL)
            --AND NOT trim(cchi_rej_reason) IN (SELECT trim(cast(sys_code as varchar(200))) FROM sy_sys_code where sys_type = 'CCHI_REJ_REASON')
            and trim(cchi_status) = 'R'
            AND TRIM(adj_code) in ('000')
            AND TRIM(CRT_USER)=TRIM(pc_crt_user)
            AND CRT_DATE=pc_crt_date;
       --2011-09-12 REF-0902 Shaman End
--2008-10-27 Ho Laam REF-0564 CR050 End

     --2013-06-26 REF-1279 CR187 RichardL start
     --Product
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 123) || '1' || SUBSTR(err_code, 125)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND length(trim(PRODUCT)) > 30
         AND TRIM(CRT_USER) = TRIM(pc_crt_user)
         AND CRT_DATE = pc_crt_date;
         
     --UHC Group #
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 124) || '1' || SUBSTR(err_code, 126)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND length(trim(UHC_GRP_NO)) > 15
         AND TRIM(CRT_USER) = TRIM(pc_crt_user)
         AND CRT_DATE = pc_crt_date;
         
     --UHC Member #
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 125) || '1' || SUBSTR(err_code, 127)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND length(trim(UHC_MBR_NO)) > 15
         AND TRIM(CRT_USER) = TRIM(pc_crt_user)
         AND CRT_DATE = pc_crt_date;
         
     --UHC Electronic Payer ID
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 126) || '1' || SUBSTR(err_code, 128)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND length(trim(UHC_PAYER_ID)) > 15
         AND TRIM(CRT_USER) = TRIM(pc_crt_user)
         AND CRT_DATE = pc_crt_date;

     --Network Options
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 127) || '1' || SUBSTR(err_code, 129)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND length(trim(NET_OPT)) > 8
         AND TRIM(CRT_USER) = TRIM(pc_crt_user)
         AND CRT_DATE = pc_crt_date;
         
     --UAE Network
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 128) || '1' || SUBSTR(err_code, 130)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND length(trim(UAE_NET)) > 8
         AND TRIM(CRT_USER) = TRIM(pc_crt_user)
         AND CRT_DATE = pc_crt_date;

     --Direct Billing
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 129) || '1' || SUBSTR(err_code, 131)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND length(trim(DIRECT_BILL)) > 10
         AND TRIM(CRT_USER) = TRIM(pc_crt_user)
         AND CRT_DATE = pc_crt_date;
         
     --Provider Notes
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 130) || '1' || SUBSTR(err_code, 132)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND length(trim(PROV_NOTES)) > 40
         AND TRIM(CRT_USER) = TRIM(pc_crt_user)
         AND CRT_DATE = pc_crt_date;

     --Patient Co-insurance
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 131) || '1' || SUBSTR(err_code, 133)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND length(trim(PATIENT_CO_INS)) > 30
         AND TRIM(CRT_USER) = TRIM(pc_crt_user)
         AND CRT_DATE = pc_crt_date;
         
     --Room
      UPDATE MR_MBR_BAT_UPD
         SET err_code = SUBSTR(err_code, 1, 132) || '1' || SUBSTR(err_code, 134)
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND length(trim(ROOM)) > 15
         AND TRIM(CRT_USER) = TRIM(pc_crt_user)
         AND CRT_DATE = pc_crt_date;
         
     --Membership Number
      UPDATE MR_MBR_BAT_UPD
         --SET err_code = SUBSTR(err_code, 1, 133) || '1' --2013-07-10 REF-1275 CR181 RichardL
         SET err_code = SUBSTR(err_code, 1, 133) || '1' || SUBSTR(err_code, 135) --2013-07-10 REF-1275 CR181 RichardL
         WHERE SUBSTR(err_code, 1, 1) = '0'
         AND length(trim(OTHER_MBRSHP_NO)) > 15
         AND TRIM(CRT_USER) = TRIM(pc_crt_user)
         AND CRT_DATE = pc_crt_date;
     --2013-06-26 REF-1279 CR187 RichardL end
         
    --2013-07-10 REF-1275 CR181 RichardL start
    --Member District
    -- Missing value
    /* 2013-10-21 REF-1275 CR181 Eric Shek, UAt - Change Dist code to optional field
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 134) || '1' || SUBSTR(err_code, 136)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND adj_code = '000'
    AND (trim(CORR_DIST_CODE) = '' OR CORR_DIST_CODE IS NULL)
    AND TRIM(CRT_USER) = TRIM(pc_crt_user)
    AND CRT_DATE = pc_crt_date;
    */
    --2015-12-11 REF-1600 CR232 Nathan Start
    --Removed, Field no longer in use
    -- Does not exist
    /*UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 134) || '2' || SUBSTR(err_code, 136)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND SUBSTR(err_code, 135, 1) = '0'
    AND adj_code = '000'
    --2013-11-07 CR181 UAT Log, Eric Shek, Start
    --AND CORR_DIST_CODE IS NOT NULL
    AND TRIM(CORR_DIST_CODE) IS NOT NULL
    --2013-11-07 CR181 UAT Log, Eric Shek, End
    AND NOT EXISTS
    (
    SELECT 1
    FROM DC_DISTRICT dc, SY_SYS_CODE sc
    WHERE dc.area_code = sc.sys_code
    and sc.SYS_TYPE IN ('COUNTRY_CODE','AREA_CODE')
    AND TRIM(dc.dist_code) = TRIM(CORR_DIST_CODE)
    )
    AND TRIM(CRT_USER) = TRIM(pc_crt_user)
    AND CRT_DATE = pc_crt_date;
    --Too long
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 134) || '3' || SUBSTR(err_code, 136)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND SUBSTR(err_code, 135, 1) = '0'
    AND adj_code = '000'
    AND length(trim(CORR_DIST_CODE)) > 4
    AND TRIM(CRT_USER) = TRIM(pc_crt_user)
    AND CRT_DATE = pc_crt_date;*/
    --2015-12-11 REF-1600 CR232 Nathan End

    --Member Profession
    -- Missing value
    /* 2013-10-21 REF-1275 CR181 Eric Shek, UAT- ChangeProfession code to optional field
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 135) || '1' || SUBSTR(err_code, 137)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND adj_code = '000'
    AND (trim(PROFESSION_CODE) = '' OR PROFESSION_CODE IS NULL)
    AND TRIM(CRT_USER) = TRIM(pc_crt_user)
    AND CRT_DATE = pc_crt_date;
    -- Does not exist
*/
    
    --2015-12-11 REF-1600 CR232 Nathan Start
    --Removed, Field no longer in use
    /*UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 135) || '2' || SUBSTR(err_code, 137)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND SUBSTR(err_code, 136, 1) = '0'
    AND adj_code = '000'
    --2013-11-07 CR181 UAT Log, Eric Shek, Start
    --AND PROFESSION_CODE IS NOT NULL
    AND TRIM(PROFESSION_CODE) IS NOT NULL
    --2013-11-07 CR181 UAT Log, Eric Shek, End
    AND
    (
    TRIM(PROFESSION_CODE) <> 'E'
    AND
    NOT EXISTS
    (
    SELECT 1 FROM SY_SYS_CODE 
    WHERE SYS_TYPE IN ('PROFESSION')
    AND TRIM(SYS_CODE) = TRIM(PROFESSION_CODE)
    )
    )
    AND TRIM(CRT_USER) = TRIM(pc_crt_user)
    AND CRT_DATE = pc_crt_date;
    --Too long
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 135) || '3' || SUBSTR(err_code, 137)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND SUBSTR(err_code, 136, 1) = '0'
    AND adj_code = '000'
    AND length(trim(PROFESSION_CODE)) > 4
    AND TRIM(CRT_USER) = TRIM(pc_crt_user)
    AND CRT_DATE = pc_crt_date;*/
    --2015-12-11 REF-1600 CR232 Nathan End
    --2013-07-10 REF-1275 CR181 RichardL end
    
    --2014-04-07 REF-1454 CR211 Nathan Start
    --ID Type
    
    --Missing Value
    --2014-04-15 REF-1454 CR211 Nathan Start
    /*UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 136) || '1' || SUBSTR(err_code, 138)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 137, 1) = '0'
       AND (TRIM(ID_TYPE) = '' OR ID_TYPE IS NULL)
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;*/
    --2014-04-15 REF-1454 CR211 Nathan Start
    
    /*--Too Long   
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 136) || '2' || SUBSTR(err_code, 138)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 137, 1) = '0'
       AND LENGTH(TRIM(ID_TYPE)) > 1;
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;*/
       
    --Does not Exist
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 136) || '2' || SUBSTR(err_code, 138)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 137, 1) = '0'
       AND TRIM(ID_TYPE) IS NOT NULL
       AND NOT EXISTS
       (
       SELECT 1 FROM SY_SYS_CODE 
       WHERE SYS_TYPE IN ('ID_TYPE')
       AND TRIM(SYS_CODE) = TRIM(ID_TYPE)
       )
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
    
    --2017-03-15 REF-2502 CR311 Nathan Start
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 136) || '3' || SUBSTR(err_code, 138)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 137, 1) = '0'
       AND TRIM(ID_TYPE) IS NOT NULL
       AND TRIM(CTRY_CODE) IS NOT NULL
       AND ((ID_TYPE = '1' AND CTRY_CODE <> '966')
            OR
            (ID_TYPE IN ('2', '4') AND (MR_SCR_PKG.IS_GCC_COUNTRY(CTRY_CODE) = 'Y' OR CTRY_CODE = '966'))
            OR
            (ID_TYPE = '3' AND CTRY_CODE = '966')
           )
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
    
    UPDATE MR_MBR_BAT_UPD upd
     SET err_code = SUBSTR(err_code, 1, 136) || '3' || SUBSTR(err_code, 138)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 137, 1) = '0'
       AND TRIM(ID_TYPE) IS NULL
       AND TRIM(CTRY_CODE) IS NOT NULL
       AND ((CTRY_CODE <> '966'
             AND EXISTS (SELECT 1
                         FROM MR_MEMBER mbr
                         WHERE mbr.CONT_NO = upd.CONT_NO AND mbr.MBR_NO = upd.MBR_NO
                         AND mbr.ID_TYPE = '1')
            )
            OR
            ((MR_SCR_PKG.IS_GCC_COUNTRY(CTRY_CODE) = 'Y' OR CTRY_CODE = '966')
             AND EXISTS (SELECT 1
                         FROM MR_MEMBER mbr
                         WHERE mbr.CONT_NO = upd.CONT_NO AND mbr.MBR_NO = upd.MBR_NO
                         AND mbr.ID_TYPE IN ('2', '4'))
            )
            OR
            (CTRY_CODE = '966'
             AND EXISTS (SELECT 1
                         FROM MR_MEMBER mbr
                         WHERE mbr.CONT_NO = upd.CONT_NO AND mbr.MBR_NO = upd.MBR_NO
                         AND mbr.ID_TYPE = '3')
            )
           )
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
    --2017-03-15 REF-2502 CR311 Nathan End
    
    
    --CCHI Member Profession
    
    --Missing Value
    --2014-04-15 REF-1454 CR211 Nathan Start
    /*UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 137) || '1' || SUBSTR(err_code, 139)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 138, 1) = '0'
       AND (TRIM(PROFESSION_CODE) = '' OR PROFESSION_CODE IS NULL)
       AND (TRIM(CCHI_JOB_CODE) = '' OR CCHI_JOB_CODE IS NULL)
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;*/
    --2014-04-15 REF-1454 CR211 Nathan End
    
    --Too Long   
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 137) || '2' || SUBSTR(err_code, 139)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 138, 1) = '0'
       AND LENGTH(TRIM(CCHI_JOB_CODE)) > 8
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
       
    --Does not Exist
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 137) || '3' || SUBSTR(err_code, 139)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 138, 1) = '0'
       AND TRIM(CCHI_JOB_CODE) IS NOT NULL
       AND NOT EXISTS
       (
       SELECT 1 FROM MR_PROFESSION 
--2016-04-21 Larry REF-2134 Prod Log Start
--       WHERE TRIM(PROF_CODE) = TRIM(CCHI_JOB_CODE)
       WHERE PROF_CODE = TRIM(CCHI_JOB_CODE)
--2016-04-21 Larry REF-2134 Prod Log End
       )
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
       
    --Is not Active
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 137) || '4' || SUBSTR(err_code, 139)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 138, 1) = '0'
       AND TRIM(CCHI_JOB_CODE) IS NOT NULL
--2016-04-21 Larry REF-2134 Prod Log Start
--       AND NOT EXISTS
       AND EXISTS
--2016-04-21 Larry REF-2134 Prod Log End
       (
       SELECT 1 FROM MR_PROFESSION 
--2016-04-21 Larry REF-2134 Prod Log Start
--       WHERE TRIM(PROF_CODE) = TRIM(CCHI_JOB_CODE)
       WHERE PROF_CODE = TRIM(CCHI_JOB_CODE)
--       AND ACTIVE_STATUS = 'A'
       AND ACTIVE_STATUS = 'I'
--2016-04-21 Larry REF-2134 Prod Log End
       )
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
    
    
    --CCHI Member District
    
    --Missing Value
    --2014-04-15 REF-1454 CR211 Nathan Start
    /*UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 138) || '1' || SUBSTR(err_code, 140)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 139, 1) = '0'
       AND (TRIM(CORR_DIST_CODE) = '' OR CORR_DIST_CODE IS NULL)
       AND (TRIM(CCHI_CITY_CODE) = '' OR CCHI_CITY_CODE IS NULL)
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;*/
    --2014-04-15 REF-1454 CR211 Nathan End
    
    --Too Long   
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 138) || '2' || SUBSTR(err_code, 140)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 139, 1) = '0'
       AND LENGTH(TRIM(CCHI_CITY_CODE)) > 4
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
       
    --Does not Exist
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 138) || '3' || SUBSTR(err_code, 140)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 139, 1) = '0'
       AND TRIM(CCHI_CITY_CODE) IS NOT NULL
       AND NOT EXISTS
       (
       SELECT 1 FROM MR_DISTRICT 
       WHERE TRIM(CITY_CODE) = TRIM(CCHI_CITY_CODE)
       )
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
    
    
    --Expiry Date
    
    --Missing Value
    --2014-04-15 REF-1454 CR211 Nathan Start
    /*UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 139) || '1' || SUBSTR(err_code, 141)
     WHERE SUBSTR(err_code, 137, 1) = '0'
       AND SUBSTR(err_code, 140, 1) = '0'
       AND (TRIM(ID_EXP_DATE) = '' OR ID_EXP_DATE IS NULL)
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;*/
    --2014-04-15 REF-1454 CR211 Nathan End
    
    
    --Marital Status
    
    --Missing Value
    --2014-04-15 REF-1454 CR211 Nathan Start
    /*UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 140) || '1' || SUBSTR(err_code, 142)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 141, 1) = '0'
       AND (TRIM(MARITAL_STATUS) = '' OR MARITAL_STATUS IS NULL)
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;*/
    --2014-04-15 REF-1454 CR211 Nathan End
    
    /*--Too Long   
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 140) || '2' || SUBSTR(err_code, 142)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 141, 1) = '0'
       AND LENGTH(TRIM(ID_TYPE)) > 1;
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;*/
       
    --Does not Exist
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 140) || '2' || SUBSTR(err_code, 142)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 141, 1) = '0'
       AND TRIM(MARITAL_STATUS) IS NOT NULL
       AND NOT EXISTS
       (
       SELECT 1 FROM SY_SYS_CODE 
       WHERE SYS_TYPE IN ('MARITAL_STATUS')
       AND TRIM(SYS_CODE) = TRIM(MARITAL_STATUS)
       )
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
    
    
    --Phone No.
    
    --Is not numeric
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 141) || '1' || SUBSTR(err_code, 143)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 142, 1) = '0'
       AND MR_BAT_PKG.GET_MBR_TYPE_GRP(Mbr_Type) = 'E'
       AND TRIM(PHONE_NO)IS NOT NULL
       AND SY_LIB_PKG.CHKNUM(TRIM(PHONE_NO)) <> 0
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
    --2014-04-07 REF-1454 CR211 Nathan End
    
    --2017-04-19 REF-2521 CR343 JimmyC Start
    --No Medical Declaration
    --Cannot be changed when the indicator at customer lever is unticked
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 142) || '1' || SUBSTR(err_code, 144)
    WHERE SUBSTR(err_code, 143, 1) = '0'
    AND NO_MED_DECL_IND IS NOT NULL
    AND EXISTS(SELECT 1 FROM MR_CUSTOMER_TBL cust
      WHERE cust.CONT_NO = MR_MBR_BAT_UPD.CONT_NO
      AND NVL(cust.NO_MED_DECL_IND,'N') = 'N')
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date;

    --Too long
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 142) || '2' || SUBSTR(err_code, 144)
    WHERE SUBSTR(err_code, 143, 1) = '0'
    AND NO_MED_DECL_IND IS NOT NULL
    AND length(trim(NO_MED_DECL_IND))>1
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date;

    -- Does not exist
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 142) || '3' || SUBSTR(err_code, 144)
    WHERE SUBSTR(err_code, 143, 1) = '0'
    AND NO_MED_DECL_IND IS NOT NULL
    AND NOT NVL(trim(NO_MED_DECL_IND), 'N') IN ('Y', 'N')
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date; 
    --2017-04-19 REF-2521 CR343 JimmyC End
	
	--2017-06-19 Teddy Chiu REF-2569 CR356 Start
	-- Does not exist
	UPDATE MR_MBR_BAT_UPD
	SET err_code = SUBSTR(err_code, 1, 143) || '1' || SUBSTR(err_code, 145)
    WHERE SUBSTR(err_code, 144, 1) = '0'
	AND FAN_CLUB_TYPE IS NOT NULL
	AND NOT EXISTS
	(
		SELECT 1 FROM SY_SYS_CODE 
		WHERE SYS_TYPE = 'FAN_CLUB_TYPE'
		AND TRIM(SYS_CODE) = TRIM(FAN_CLUB_TYPE)
	)
	AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date;
	--2017-06-19 Teddy Chiu REF-2569 CR356 End
    
    --2017-12-28 REF-2703 CR386 Nathan Start
    --Waive Threshold Limit
    UPDATE MR_MBR_BAT_UPD
     SET err_code = SUBSTR(err_code, 1, 144) || '1' || SUBSTR(err_code, 146)
     WHERE SUBSTR(err_code, 1, 1) = '0'
       AND SUBSTR(err_code, 145, 1) = '0'
       AND TRIM(WAIVE_THRS_IND) IS NOT NULL
       AND TRIM(WAIVE_THRS_IND) NOT IN ('Y', 'N')
       AND TRIM(CRT_USER)=TRIM(pc_crt_user)
       AND CRT_DATE=pc_crt_date;
    --2017-12-28 REF-2703 CR386 Nathan End
    
    --2018-06-14 REF-2842 CR414 JimmyC Start
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 145) || '1' || SUBSTR(err_code, 147)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND SUBSTR(err_code, 146, 1) = '0'
    AND TRIM(DECLARED_CONT_IND) IS NOT NULL
    AND TRIM(DECLARED_CONT_IND) NOT IN ('Y', 'N')
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date;
    --2018-06-14 REF-2842 CR414 JimmyC End
    
    --2018-08-06 REF-2880 CR403 Steven Start
    UPDATE MR_MBR_BAT_UPD upd
    SET err_code = SUBSTR(err_code, 1, 146) || '1' || SUBSTR(err_code, 148)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND SUBSTR(err_code, 147, 1) = '0'
    AND upd.PREV_MBR_NO IS NOT NULL
	AND upd.PREV_MBR_NO <> 'N'
    AND NOT EXISTS( SELECT 1 FROM MR_MEMBER mbr 
                    WHERE upd.PREV_MBR_NO = mbr.MBRSHP_NO
                    )
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date;
    --2018-08-06 REF-2880 CR403 Steven End
    
    --2018-05-28 REF-2846 (CR373) Danny Start
    --field should be 'Y' or 'N'
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 147) || '1' || SUBSTR(err_code, 149)
    WHERE SUBSTR(err_code, 148, 1) = '0'
    AND NVL(trim(EXCEPT_NORMAL_RATE_IND), 'N') NOT IN ('Y', 'N')
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date; 
    
 lv_valid_line := TRIM('32 OK');
    --field should be empty if rating method is not PH
    UPDATE MR_MBR_BAT_UPD b
    SET err_code = SUBSTR(err_code, 1, 147) || '2' || SUBSTR(err_code, 149)
    WHERE SUBSTR(err_code, 148, 1) = '0'
    AND EXCEPT_NORMAL_RATE_IND IS NOT NULL
    AND (SELECT NVL(trim(MAX(RATE_METHOD)),' ') FROM 
        MR_CONT_CLS c ,SR_PLAN_RATE s 
        WHERE c.CONT_NO = b.CONT_NO
        AND c.cont_yymm = CL_BAT_PKG.GetCurCont(b.CONT_NO,SYSDATE)
        AND c.CLS_ID =(SELECT NVL(b.CLS_ID, m.CLS_ID) FROM MR_MEMBER m 
                        WHERE m.CONT_NO = b.CONT_NO AND m.MBR_NO = b.MBR_NO)
        AND c.plan_id = s.plan_id) <> 'PH'
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date; 
    
     lv_valid_line := TRIM('33 OK');
    --No rights to change the field
    UPDATE MR_MBR_BAT_UPD b
    SET err_code = SUBSTR(err_code, 1, 147) || '3' || SUBSTR(err_code, 149)
    WHERE SUBSTR(err_code, 148, 1) = '0'
    AND EXCEPT_NORMAL_RATE_IND IS NOT NULL
    AND NOT EXISTS (select 1 from
                    sc_grp_func f, sc_user_grp g
                    where func_id = 'MRMEMBMNT02'
                    AND rights like '%A%'
                    AND f.grp_id = g.grp_id
                    AND g.user_id = user)
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date; 
    --2018-05-28 REF-2846 (CR373) Danny END
    
    --2018-12-19 REF-2919 CR454 Ken Start
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 148) || '1' || SUBSTR(err_code, 150)
    WHERE SUBSTR(err_code, 149, 1) = '0'
    AND DOB_HIJRI > TO_DATE(TO_CHAR(mbr_eff_date, 'DD/MM/YYYY', 'nls_calendar=''ENGLISH HIJRAH'''), 'DD/MM/YYYY')
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date;
    --2018-12-19 REF-2919 CR454 Ken End
    
    --2019-04-04 REF-2941 CR459 Ken Start
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 149) || '1' || SUBSTR(err_code, 151)
    WHERE SUBSTR(err_code, 150, 1) = '0'
    AND ADDITION_NO IS NOT NULL
    AND length(trim(ADDITION_NO))>15
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date;
    
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 150) || '1' || SUBSTR(err_code, 152)
    WHERE SUBSTR(err_code, 151, 1) = '0'
    AND BUILD_NO IS NOT NULL
    AND length(trim(BUILD_NO))>15
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date;
    
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 151) || '1' || SUBSTR(err_code, 153)
    WHERE SUBSTR(err_code, 152, 1) = '0'
    AND DISTRICT IS NOT NULL
    AND length(trim(DISTRICT))>40
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date;
    
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 152) || '1' || SUBSTR(err_code, 154)
    WHERE SUBSTR(err_code, 153, 1) = '0'
    AND POST_CODE IS NOT NULL
    AND length(trim(POST_CODE))>15
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date;
    
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 153) || '1' || SUBSTR(err_code, 155)
    WHERE SUBSTR(err_code, 154, 1) = '0'
    AND STREET IS NOT NULL
    AND length(trim(STREET))>40
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date;
    --2019-04-04 REF-2941 CR459 Ken End

	--2019-03-26 REF-2940 CR440 Ken Start
    UPDATE MR_MBR_BAT_UPD
    --2022-01-18 Teddy Chiu REF-3821 CR667 Start
    --SET err_code = SUBSTR(err_code, 1, 154) || '1' || SUBSTR(err_code, 151)
    --WHERE SUBSTR(err_code, 150, 1) = '0'
    SET err_code = SUBSTR(err_code, 1, 154) || '1' || SUBSTR(err_code, 156)
    WHERE SUBSTR(err_code, 155, 1) = '0'
    --2022-01-18 Teddy Chiu REF-3821 CR667 End
    AND TPA_GROUP IS NOT NULL
    AND length(trim(TPA_GROUP))>18
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date;
    
    UPDATE MR_MBR_BAT_UPD
    --2022-01-18 Teddy Chiu REF-3821 CR667 Start
    --SET err_code = SUBSTR(err_code, 1, 155) || '1' || SUBSTR(err_code, 152)
    --WHERE SUBSTR(err_code, 151, 1) = '0'
    SET err_code = SUBSTR(err_code, 1, 155) || '1' || SUBSTR(err_code, 157)
    WHERE SUBSTR(err_code, 156, 1) = '0'
    --2022-01-18 Teddy Chiu REF-3821 CR667 End
    AND TPA_ASSIGNMENT IS NOT NULL
    AND length(trim(TPA_ASSIGNMENT))>18
    AND TRIM(CRT_USER)=TRIM(pc_crt_user) 
    AND CRT_DATE=pc_crt_date;
    --2019-03-26 REF-2940 CR440 Ken End
    
    --2022-01-18 Teddy Chiu REF-3821 CR667 Start
    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 156) || '1' || SUBSTR(err_code, 158)
    WHERE SUBSTR(err_code, 157, 1) = '0'
    AND PREFER_CONTACT_METHOD IS NOT NULL
    AND NOT EXISTS
    (
     SELECT 1 FROM SY_SYS_CODE
     WHERE SYS_TYPE = 'MBR_PREFER_CONTACT'
     AND TRIM(SYS_CODE) = TRIM(PREFER_CONTACT_METHOD)
    )
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date;

    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 157) || '1' || SUBSTR(err_code, 159)
    WHERE SUBSTR(err_code, 157, 1) = '0'
    AND SUBSTR(err_code, 158, 1) = '0'
    AND PREFER_CONTACT_METHOD = 'I'
    AND TRIM(INTER_MOBILE_CTRY_CODE) IS NULL
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date;

    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 157) || '2' || SUBSTR(err_code, 159)
    WHERE SUBSTR(err_code, 157, 1) = '0'
    AND SUBSTR(err_code, 158, 1) = '0'
    AND PREFER_CONTACT_METHOD = 'I'
    AND NOT EXISTS
    (
     SELECT 1 FROM SY_INTER_MOBILE_CTRY
     WHERE CTRY_CODE = INTER_MOBILE_CTRY_CODE
    )
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date;

    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 158) || '1' || SUBSTR(err_code, 160)
    WHERE SUBSTR(err_code, 157, 1) = '0'
    AND SUBSTR(err_code, 158, 1) = '0'
    AND SUBSTR(err_code, 159, 1) = '0'
    AND PREFER_CONTACT_METHOD = 'I'
    AND TRIM(INTER_MOBILE_NO) IS NULL
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date;

    UPDATE MR_MBR_BAT_UPD
    SET err_code = SUBSTR(err_code, 1, 158) || '2' || SUBSTR(err_code, 160)
    WHERE SUBSTR(err_code, 157, 1) = '0'
    AND SUBSTR(err_code, 158, 1) = '0'
    AND SUBSTR(err_code, 159, 1) = '0'
    AND PREFER_CONTACT_METHOD = 'I'
    AND NOT EXISTS
    (
     SELECT 1 FROM SY_INTER_MOBILE_CTRY
     WHERE CTRY_CODE = INTER_MOBILE_CTRY_CODE
     AND LENGTH(TRIM(INTER_MOBILE_NO)) BETWEEN MIN_LEN_MOBILE_NO AND MAX_LEN_MOBILE_NO
    )
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date;
    --2022-01-18 Teddy Chiu REF-3821 CR667 End
    
    --2023-09-11 Dave Wong REF-4665 CR830 Start
    UPDATE MR_MBR_BAT_CRT
    SET err_code = SUBSTR(err_code, 1, 159) || '1' || SUBSTR(err_code, 161)
    WHERE SUBSTR(err_code, 160, 1) = '0'
    AND TRIM(TAHAQAQ_STATUS) IS NOT NULL
    AND TRIM(TAHAQAQ_STATUS) NOT IN('M','N','X','F')
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date;

    UPDATE MR_MBR_BAT_CRT
    SET err_code = SUBSTR(err_code, 1, 160) || '1' || SUBSTR(err_code, 162)
    WHERE SUBSTR(err_code, 161, 1) = '0'
    AND TAHAQAQ_VERIFIED_DATE IS NULL
    AND TRIM(TAHAQAQ_STATUS) IS NOT NULL
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date;
    --2023-09-11 Dave Wong REF-4665 CR830 End
    
    --2015-07-27 Teddy Chiu REF-1600 CR271 Start
    UPDATE MR_MBR_BAT_UPD bat
    SET err_code = SUBSTR(err_code, 1, 66) || '1' || SUBSTR(err_code, 68)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND EXISTS(SELECT 1
                FROM MR_CONTRACT cont, MR_MEMBER mbr
                WHERE cont.cont_no = mbr.cont_no
                AND cont.cont_no = bat.cont_no
                AND mbr.mbrshp_no = bat.mbrshp_no
                AND cont.cont_yymm = MR_SCR_PKG.Get_Cur_Contract(cont.cont_no, GREATEST(TRUNC(SYSDATE), mbr.eff_date))
                AND cont.CCHI_UPLOAD_IND <> 'A'
        )
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date
    --2015-12-23 CR271 Prod Hot Fix Eric Shek, Start
    AND trim(bat.action_type) is not null
    --2015-12-23 CR271 Prod Hot Fix Eric Shek, End
    ;
    
    UPDATE MR_MBR_BAT_UPD bat
    SET err_code = SUBSTR(err_code, 1, 66) || '2' || SUBSTR(err_code, 68)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND SUBSTR(err_code, 67, 1) = '0'
    AND EXISTS(SELECT 1
                FROM MR_MEMBER mbr
                WHERE mbr.mbrshp_no = bat.mbrshp_no
                AND mbr.CCHI_UPLOAD_CONT_YYMM <> MR_SCR_PKG.Get_Cur_Contract(bat.cont_no, GREATEST(TRUNC(SYSDATE), mbr.eff_date))
        )
--2016-01-05 REF-2024 Prod Log Eric Shek, Start - Add Action Type 2 to exclude validation checking.
        --AND TRIM(bat.action_type) NOT IN ('1', '7', '8')
        AND TRIM(bat.action_type) NOT IN ('1', '7', '8', '2')
--2016-01-05 REF-2024 Prod Log Eric Shek, Start - Add Action Type 2 to exclude validation checking.        
        --2015-12-24 CR271 Prod Hot Fix Eric Shek, Start
        AND TRIM(bat.action_type) IS NOT NULL
        --2015-12-24 CR271 Prod Hot Fix Eric Shek, End
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date;
       
	--2022-10-18 REF-4168 CR715 Dave Comment Start
	/*
    UPDATE MR_MBR_BAT_UPD bat
    SET err_code = SUBSTR(err_code, 1, 66) || '3' || SUBSTR(err_code, 68)
    WHERE SUBSTR(err_code, 1, 1) = '0'
    AND SUBSTR(err_code, 67, 1) = '0'
    AND EXISTS(SELECT 1
                FROM MR_CONTRACT cont, MR_MEMBER mbr
                WHERE cont.cont_no = mbr.cont_no
                AND mbr.mbrshp_no = bat.mbrshp_no  
                AND bat.mbr_eff_date <= cont.term_date
                AND cont.cont_yymm = MR_SCR_PKG.Get_Cur_Contract(cont.cont_no, SYSDATE)
                AND mbr.CCHI_UPLOAD_CONT_YYMM <> cont.cont_yymm
        )
    AND adj_code = '701'
    --2015-12-24 CR271 Prod Hot Fix Eric Shek, Start
    AND TRIM(bat.action_type) IS NOT NULL
    --2015-12-24 CR271 Prod Hot Fix Eric Shek, End
    AND TRIM(CRT_USER)=TRIM(pc_crt_user)
    AND CRT_DATE=pc_crt_date;
    --2015-07-27 Teddy Chiu REF-1600 CR271 End
	*/
	--2022-10-18 REF-4168 CR715 Dave Comment End
	
EXCEPTION
   WHEN OTHERS THEN
      pn_status := ln_check;
      pv_errmsg := '(((V1:' || NVL(lv_valid_line, ' ') || '-' || SQLERRM || ')))';
END MRUPDMBAT01_Validate1;
