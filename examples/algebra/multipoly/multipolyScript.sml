open HolKernel boolLib bossLib Parse dep_rewrite
     pairTheory pred_setTheory listTheory helperListTheory bagTheory ringTheory
     polynomialTheory polyWeakTheory polyRingTheory polyEvalTheory

val _ = new_theory"multipoly"

(* stuff that should be moved *)

open monoidTheory groupTheory helperSetTheory

(* uses helperSetTheory so cannot move to bagTheory as-is *)
Theorem BAG_OF_SET_IMAGE_INJ:
  !f s.
  (!x y. x IN s /\ y IN s /\ f x = f y ==> x = y) ==>
  BAG_OF_SET (IMAGE f s) = BAG_IMAGE f (BAG_OF_SET s)
Proof
  rw[FUN_EQ_THM, BAG_OF_SET, BAG_IMAGE_DEF]
  \\ rw[] \\ gs[GSYM BAG_OF_SET]
  \\ gs[BAG_FILTER_BAG_OF_SET]
  \\ simp[BAG_CARD_BAG_OF_SET]
  >- (
    irule SING_CARD_1
    \\ simp[SING_TEST, GSYM pred_setTheory.MEMBER_NOT_EMPTY]
    \\ metis_tac[] )
  >- simp[EXTENSION]
  \\ qmatch_asmsub_abbrev_tac`INFINITE z`
  \\ `z = {}` suffices_by metis_tac[FINITE_EMPTY]
  \\ simp[EXTENSION, Abbr`z`]
QED

Overload GITBAG = ``\(g:'a monoid) s b. ITBAG g.op s b``;

Theorem GITBAG_THM =
  ITBAG_THM |> CONV_RULE SWAP_FORALL_CONV
  |> INST_TYPE [beta |-> alpha] |> Q.SPEC`(g:'a monoid).op`
  |> GEN_ALL

Theorem GITBAG_EMPTY[simp]:
  !g a. GITBAG g {||} a = a
Proof
  rw[ITBAG_EMPTY]
QED

Theorem GITBAG_INSERT:
  !b. FINITE_BAG b ==>
    !g x a. GITBAG g (BAG_INSERT x b) a =
              GITBAG g (BAG_REST (BAG_INSERT x b))
                (g.op (BAG_CHOICE (BAG_INSERT x b)) a)
Proof
  rw[ITBAG_INSERT]
QED

Theorem SUBSET_COMMUTING_ITBAG_INSERT:
  !f b t.
    SET_OF_BAG b SUBSET t /\ closure_comm_assoc_fun f t /\ FINITE_BAG b ==>
          !x a::t. ITBAG f (BAG_INSERT x b) a = ITBAG f b (f x a)
Proof
  simp[RES_FORALL_THM]
  \\ rpt gen_tac \\ strip_tac
  \\ completeInduct_on `BAG_CARD b`
  \\ rw[]
  \\ simp[ITBAG_INSERT, BAG_REST_DEF, EL_BAG]
  \\ qmatch_goalsub_abbrev_tac`{|c|}`
  \\ `BAG_IN c (BAG_INSERT x b)` by PROVE_TAC[BAG_CHOICE_DEF, BAG_INSERT_NOT_EMPTY]
  \\ fs[BAG_IN_BAG_INSERT]
  \\ `?b0. b = BAG_INSERT c b0` by PROVE_TAC [BAG_IN_BAG_DELETE, BAG_DELETE]
  \\ `BAG_DIFF (BAG_INSERT x b) {| c |} = BAG_INSERT x b0`
  by SRW_TAC [][BAG_INSERT_commutes]
  \\ pop_assum SUBST_ALL_TAC
  \\ first_x_assum(qspec_then`BAG_CARD b0`mp_tac)
  \\ `FINITE_BAG b0` by FULL_SIMP_TAC (srw_ss()) []
  \\ impl_keep_tac >- SRW_TAC [numSimps.ARITH_ss][BAG_CARD_THM]
  \\ disch_then(qspec_then`b0`mp_tac)
  \\ impl_tac >- simp[]
  \\ impl_tac >- fs[SUBSET_DEF]
  \\ impl_tac >- simp[]
  \\ strip_tac
  \\ first_assum(qspec_then`x`mp_tac)
  \\ first_x_assum(qspec_then`c`mp_tac)
  \\ impl_keep_tac >- fs[SUBSET_DEF]
  \\ disch_then(qspec_then`f x a`mp_tac)
  \\ impl_keep_tac >- metis_tac[closure_comm_assoc_fun_def]
  \\ strip_tac
  \\ impl_tac >- simp[]
  \\ disch_then(qspec_then`f c a`mp_tac)
  \\ impl_keep_tac >- metis_tac[closure_comm_assoc_fun_def]
  \\ disch_then SUBST1_TAC
  \\ simp[]
  \\ metis_tac[closure_comm_assoc_fun_def]
QED

Theorem COMMUTING_GITBAG_INSERT:
  !g b. AbelianMonoid g /\ FINITE_BAG b /\ SET_OF_BAG b SUBSET G ==>
  !x a::(G). GITBAG g (BAG_INSERT x b) a = GITBAG g b (g.op x a)
Proof
  rpt strip_tac
  \\ irule SUBSET_COMMUTING_ITBAG_INSERT
  \\ metis_tac[abelian_monoid_op_closure_comm_assoc_fun]
QED

Theorem GITBAG_INSERT_THM =
  SIMP_RULE(srw_ss())[RES_FORALL_THM, PULL_FORALL, AND_IMP_INTRO]
  COMMUTING_GITBAG_INSERT

Theorem GITBAG_UNION:
  !g. AbelianMonoid g ==>
  !b1. FINITE_BAG b1 ==> !b2. FINITE_BAG b2 /\ SET_OF_BAG b1 SUBSET G
                                            /\ SET_OF_BAG b2 SUBSET G ==>
  !a. a IN G ==> GITBAG g (BAG_UNION b1 b2) a = GITBAG g b2 (GITBAG g b1 a)
Proof
  gen_tac \\ strip_tac
  \\ ho_match_mp_tac STRONG_FINITE_BAG_INDUCT
  \\ rw[]
  \\ simp[BAG_UNION_INSERT]
  \\ DEP_REWRITE_TAC[GITBAG_INSERT_THM]
  \\ gs[SUBSET_DEF]
  \\ simp[GSYM CONJ_ASSOC]
  \\ conj_tac >- metis_tac[]
  \\ first_x_assum irule
  \\ simp[]
  \\ fs[AbelianMonoid_def]
QED

Theorem GITBAG_in_carrier:
  !g. AbelianMonoid g ==>
  !b. FINITE_BAG b ==> !a. SET_OF_BAG b SUBSET G /\ a IN G ==> GITBAG g b a IN G
Proof
  ntac 2 strip_tac
  \\ ho_match_mp_tac STRONG_FINITE_BAG_INDUCT
  \\ simp[]
  \\ rpt strip_tac
  \\ drule COMMUTING_GITBAG_INSERT
  \\ disch_then (qspec_then`b`mp_tac)
  \\ fs[SUBSET_DEF]
  \\ simp[RES_FORALL_THM, PULL_FORALL]
  \\ strip_tac
  \\ last_x_assum irule
  \\ metis_tac[monoid_op_element, AbelianMonoid_def]
QED

Overload GBAG = ``\(g:'a monoid) b. GITBAG g b g.id``;

Theorem GBAG_in_carrier:
  !g b. AbelianMonoid g /\ FINITE_BAG b /\ SET_OF_BAG b SUBSET G ==> GBAG g b IN G
Proof
  rw[]
  \\ irule GITBAG_in_carrier
  \\ metis_tac[AbelianMonoid_def, monoid_id_element]
QED

Theorem GITBAG_GBAG:
  !g. AbelianMonoid g ==>
  !b. FINITE_BAG b ==> !a. a IN g.carrier /\ SET_OF_BAG b SUBSET g.carrier ==>
      GITBAG g b a = g.op a (GITBAG g b g.id)
Proof
  ntac 2 strip_tac
  \\ ho_match_mp_tac STRONG_FINITE_BAG_INDUCT
  \\ rw[] >- fs[AbelianMonoid_def]
  \\ DEP_REWRITE_TAC[GITBAG_INSERT_THM]
  \\ simp[]
  \\ conj_asm1_tac >- fs[SUBSET_DEF, AbelianMonoid_def]
  \\ irule EQ_TRANS
  \\ qexists_tac`g.op (g.op e a) (GBAG g b)`
  \\ conj_tac >- (
    first_x_assum irule
    \\ metis_tac[AbelianMonoid_def, monoid_op_element] )
  \\ first_x_assum(qspec_then`e`mp_tac)
  \\ simp[]
  \\ `g.op e (#e) = e` by metis_tac[AbelianMonoid_def, monoid_id]
  \\ pop_assum SUBST1_TAC
  \\ disch_then SUBST1_TAC
  \\ fs[AbelianMonoid_def]
  \\ irule monoid_assoc
  \\ simp[]
  \\ irule GBAG_in_carrier
  \\ simp[AbelianMonoid_def]
QED

Theorem GBAG_UNION:
  AbelianMonoid g /\ FINITE_BAG b1 /\ FINITE_BAG b2 /\
  SET_OF_BAG b1 SUBSET g.carrier /\ SET_OF_BAG b2 SUBSET g.carrier ==>
  GBAG g (BAG_UNION b1 b2) = g.op (GBAG g b1) (GBAG g b2)
Proof
  rpt strip_tac
  \\ DEP_REWRITE_TAC[GITBAG_UNION]
  \\ simp[]
  \\ conj_tac >- fs[AbelianMonoid_def]
  \\ DEP_ONCE_REWRITE_TAC[GITBAG_GBAG]
  \\ simp[]
  \\ irule GBAG_in_carrier
  \\ simp[]
QED

Theorem GITBAG_BAG_IMAGE_op:
  !g. AbelianMonoid g ==>
  !b. FINITE_BAG b ==>
  !p q a. IMAGE p (SET_OF_BAG b) SUBSET g.carrier /\
          IMAGE q (SET_OF_BAG b) SUBSET g.carrier /\ a IN g.carrier ==>
  GITBAG g (BAG_IMAGE (\x. g.op (p x) (q x)) b) a =
  g.op (GITBAG g (BAG_IMAGE p b) a) (GBAG g (BAG_IMAGE q b))
Proof
  ntac 2 strip_tac
  \\ ho_match_mp_tac STRONG_FINITE_BAG_INDUCT
  \\ rw[] >- fs[AbelianMonoid_def]
  \\ DEP_REWRITE_TAC[GITBAG_INSERT_THM]
  \\ conj_asm1_tac
  >- (
    gs[SUBSET_DEF, PULL_EXISTS]
    \\ gs[AbelianMonoid_def] )
  \\ qmatch_goalsub_abbrev_tac`GITBAG g bb aa`
  \\ first_assum(qspecl_then[`p`,`q`,`aa`]mp_tac)
  \\ impl_tac >- (
    fs[SUBSET_DEF, PULL_EXISTS, Abbr`aa`]
    \\ fs[AbelianMonoid_def] )
  \\ simp[]
  \\ disch_then kall_tac
  \\ simp[Abbr`aa`]
  \\ DEP_ONCE_REWRITE_TAC[GITBAG_GBAG]
  \\ conj_asm1_tac >- (
    fs[SUBSET_DEF, PULL_EXISTS]
    \\ fs[AbelianMonoid_def] )
  \\ irule EQ_SYM
  \\ DEP_ONCE_REWRITE_TAC[GITBAG_GBAG]
  \\ conj_asm1_tac >- fs[AbelianMonoid_def]
  \\ DEP_ONCE_REWRITE_TAC[GITBAG_GBAG |> SIMP_RULE(srw_ss())[PULL_FORALL,AND_IMP_INTRO]
                          |> Q.SPECL[`g`,`b`,`g.op x y`]]
  \\ simp[]
  \\ fs[AbelianMonoid_def]
  \\ qmatch_goalsub_abbrev_tac`_ * _ * gp * ( _ * gq)`
  \\ `gp ∈ g.carrier ∧ gq ∈ g.carrier`
  by (
    unabbrev_all_tac
    \\ conj_tac \\ irule GBAG_in_carrier
    \\ fs[AbelianMonoid_def] )
  \\ drule monoid_assoc
  \\ strip_tac \\ gs[]
QED

Theorem IMP_GBAG_EQ_ID:
  AbelianMonoid g ==>
  !b. BAG_EVERY ((=) g.id) b ==> GBAG g b = g.id
Proof
  rw[]
  \\ `FINITE_BAG b`
  by (
    Cases_on`b = {||}` \\ simp[]
    \\ once_rewrite_tac[GSYM unibag_FINITE]
    \\ rewrite_tac[FINITE_BAG_OF_SET]
    \\ `SET_OF_BAG b = {g.id}`
    by (
      rw[SET_OF_BAG, FUN_EQ_THM]
      \\ fs[BAG_EVERY]
      \\ rw[EQ_IMP_THM]
      \\ Cases_on`b` \\ rw[] )
    \\ pop_assum SUBST1_TAC
    \\ simp[])
  \\ qpat_x_assum`BAG_EVERY _ _` mp_tac
  \\ pop_assum mp_tac
  \\ qid_spec_tac`b`
  \\ ho_match_mp_tac STRONG_FINITE_BAG_INDUCT
  \\ rw[] \\ gs[]
  \\ drule COMMUTING_GITBAG_INSERT
  \\ disch_then drule
  \\ impl_keep_tac
  >- (
    fs[SUBSET_DEF, BAG_EVERY]
    \\ fs[AbelianMonoid_def]
    \\ metis_tac[monoid_id_element] )
  \\ simp[RES_FORALL_THM, PULL_FORALL, AND_IMP_INTRO]
  \\ disch_then(qspecl_then[`#e`,`#e`]mp_tac)
  \\ simp[]
  \\ metis_tac[monoid_id_element, monoid_id_id, AbelianMonoid_def]
QED

Theorem GITBAG_CONG:
  !g. AbelianMonoid g ==>
  !b. FINITE_BAG b ==> !b' a a'. FINITE_BAG b' /\
        a IN g.carrier /\ SET_OF_BAG b SUBSET g.carrier /\ SET_OF_BAG b' SUBSET g.carrier
        /\ (!x. BAG_IN x (BAG_UNION b b') /\ x <> g.id ==> b x = b' x)
  ==>
  GITBAG g b a = GITBAG g b' a
Proof
  ntac 2 strip_tac
  \\ ho_match_mp_tac STRONG_FINITE_BAG_INDUCT \\ rw[]
  >- (
    fs[BAG_IN, BAG_INN, EMPTY_BAG]
    \\ DEP_ONCE_REWRITE_TAC[GITBAG_GBAG]
    \\ simp[]
    \\ irule EQ_TRANS
    \\ qexists_tac`g.op a g.id`
    \\ conj_tac >- fs[AbelianMonoid_def]
    \\ AP_TERM_TAC
    \\ irule EQ_SYM
    \\ irule IMP_GBAG_EQ_ID
    \\ simp[BAG_EVERY, BAG_IN, BAG_INN]
    \\ metis_tac[])
  \\ DEP_REWRITE_TAC[GITBAG_INSERT_THM]
  \\ simp[]
  \\ fs[SET_OF_BAG_INSERT]
  \\ Cases_on`e = g.id`
  >- (
    fs[AbelianMonoid_def]
    \\ first_x_assum irule
    \\ simp[]
    \\ fs[BAG_INSERT]
    \\ metis_tac[] )
  \\ `BAG_IN e b'`
  by (
    simp[BAG_IN, BAG_INN]
    \\ fs[BAG_INSERT]
    \\ first_x_assum(qspec_then`e`mp_tac)
    \\ simp[] )
  \\ drule BAG_DECOMPOSE
  \\ disch_then(qx_choose_then`b2`strip_assume_tac)
  \\ pop_assum SUBST_ALL_TAC
  \\ DEP_REWRITE_TAC[GITBAG_INSERT_THM]
  \\ simp[] \\ fs[SET_OF_BAG_INSERT]
  \\ first_x_assum irule \\ simp[]
  \\ fs[BAG_INSERT, AbelianMonoid_def]
  \\ qx_gen_tac`x`
  \\ disch_then assume_tac
  \\ first_x_assum(qspec_then`x`mp_tac)
  \\ impl_tac >- metis_tac[]
  \\ IF_CASES_TAC \\ simp[]
QED

Theorem GBAG_IMAGE_PARTITION:
  AbelianMonoid g /\ FINITE s ==>
  !b. FINITE_BAG b ==>
    IMAGE f (SET_OF_BAG b) SUBSET G /\
    (!x. BAG_IN x b ==> ?P. P IN s /\ P x) /\
    (!x P1 P2. BAG_IN x b /\ P1 IN s /\ P2 IN s /\ P1 x /\ P2 x ==> P1 = P2)
  ==>
    GBAG g (BAG_IMAGE (λP. GBAG g (BAG_IMAGE f (BAG_FILTER P b))) (BAG_OF_SET s)) =
    GBAG g (BAG_IMAGE f b)
Proof
  strip_tac
  \\ ho_match_mp_tac STRONG_FINITE_BAG_INDUCT
  \\ simp[]
  \\ conj_tac
  >- (
    irule IMP_GBAG_EQ_ID
    \\ simp[BAG_EVERY]
    \\ rw[]
    \\ imp_res_tac BAG_IN_BAG_IMAGE_IMP
    \\ fs[] )
  \\ rpt strip_tac
  \\ fs[SET_OF_BAG_INSERT]
  \\ `∃P. P IN s /\ P e` by metis_tac[]
  \\ `∃s0. s = P INSERT s0 /\ P NOTIN s0` by metis_tac[DECOMPOSITION]
  \\ BasicProvers.VAR_EQ_TAC
  \\ simp[BAG_OF_SET_INSERT_NON_ELEMENT]
  \\ DEP_REWRITE_TAC[BAG_IMAGE_FINITE_INSERT]
  \\ qpat_x_assum`_ ⇒ _`mp_tac
  \\ impl_tac >- metis_tac[]
  \\ strip_tac
  \\ conj_tac >- metis_tac[FINITE_INSERT, FINITE_BAG_OF_SET]
  \\ qmatch_goalsub_abbrev_tac`BAG_IMAGE ff (BAG_OF_SET s0)`
  \\ `BAG_IMAGE ff (BAG_OF_SET s0) =
      BAG_IMAGE (\P. GBAG g (BAG_IMAGE f (BAG_FILTER P b))) (BAG_OF_SET s0)`
  by (
    irule BAG_IMAGE_CONG
    \\ simp[Abbr`ff`]
    \\ rw[]
    \\ metis_tac[IN_INSERT] )
  \\ simp[Abbr`ff`]
  \\ pop_assum kall_tac
  \\ rpt(first_x_assum(qspec_then`ARB`kall_tac))
  \\ pop_assum mp_tac
  \\ simp[BAG_OF_SET_INSERT_NON_ELEMENT]
  \\ DEP_REWRITE_TAC[GITBAG_INSERT_THM]
  \\ fs[AbelianMonoid_def]
  \\ conj_asm1_tac >- fs[SUBSET_DEF, PULL_EXISTS]
  \\ conj_asm1_tac >- (
    fs[SUBSET_DEF, PULL_EXISTS]
    \\ rw[] \\ irule GITBAG_in_carrier
    \\ fs[SUBSET_DEF, PULL_EXISTS, AbelianMonoid_def] )
  \\ simp[]
  \\ DEP_REWRITE_TAC[GITBAG_INSERT_THM]
  \\ simp[]
  \\ conj_asm1_tac
  >- (
    simp[AbelianMonoid_def]
    \\ irule GITBAG_in_carrier
    \\ simp[AbelianMonoid_def] )
  \\ simp[]
  \\ DEP_ONCE_REWRITE_TAC[GITBAG_GBAG] \\ simp[] \\ strip_tac
  \\ DEP_ONCE_REWRITE_TAC[GITBAG_GBAG] \\ simp[]
  \\ DEP_ONCE_REWRITE_TAC[GITBAG_GBAG] \\ simp[]
  \\ DEP_REWRITE_TAC[monoid_assoc]
  \\ simp[]
  \\ conj_tac >- ( irule GBAG_in_carrier \\ simp[] )
  \\ irule EQ_SYM
  \\ irule GITBAG_GBAG
  \\ simp[]
QED

Theorem GBAG_PARTITION:
  AbelianMonoid g /\ FINITE s /\ FINITE_BAG b /\ SET_OF_BAG b SUBSET G /\
    (!x. BAG_IN x b ==> ?P. P IN s /\ P x) /\
    (!x P1 P2. BAG_IN x b /\ P1 IN s /\ P2 IN s /\ P1 x /\ P2 x ==> P1 = P2)
  ==>
    GBAG g (BAG_IMAGE (λP. GBAG g (BAG_FILTER P b)) (BAG_OF_SET s)) = GBAG g b
Proof
  strip_tac
  \\ `!P. FINITE_BAG (BAG_FILTER P b)` by metis_tac[FINITE_BAG_FILTER]
  \\ `GBAG g b = GBAG g (BAG_IMAGE I b)` by metis_tac[BAG_IMAGE_FINITE_I]
  \\ pop_assum SUBST1_TAC
  \\ `(λP. GBAG g (BAG_FILTER P b)) = λP. GBAG g (BAG_IMAGE I (BAG_FILTER P b))`
  by simp[FUN_EQ_THM]
  \\ pop_assum SUBST1_TAC
  \\ irule GBAG_IMAGE_PARTITION
  \\ simp[]
  \\ metis_tac[]
QED

Theorem ring_mult_lsum:
  Ring r /\ c IN r.carrier ==>
  !b. FINITE_BAG b ==> SET_OF_BAG b SUBSET r.carrier ==>
  r.prod.op (GBAG r.sum b) c
  = GBAG r.sum (BAG_IMAGE (\x. r.prod.op x c) b)
Proof
  strip_tac
  \\ ho_match_mp_tac STRONG_FINITE_BAG_INDUCT
  \\ simp[]
  \\ rpt strip_tac
  \\ fs[SET_OF_BAG_INSERT]
  \\ DEP_REWRITE_TAC[GITBAG_INSERT_THM]
  \\ simp[]
  \\ conj_asm1_tac
  >- (
    fs[SUBSET_DEF, PULL_EXISTS]
    \\ metis_tac[Ring_def, AbelianMonoid_def, AbelianGroup_def, Group_def] )
  \\ DEP_ONCE_REWRITE_TAC[GITBAG_GBAG]
  \\ simp[]
  \\ DEP_REWRITE_TAC[ring_mult_ladd]
  \\ simp[]
  \\ conj_tac
  >- (
    `r.carrier = r.sum.carrier` by metis_tac[ring_carriers]
    \\ pop_assum SUBST1_TAC
    \\ irule GBAG_in_carrier
    \\ simp[] )
  \\ irule EQ_SYM
  \\ irule GITBAG_GBAG
  \\ simp[]
QED

Theorem ring_mult_rsum:
  Ring r /\ c IN r.carrier ==>
  !b. FINITE_BAG b ==> SET_OF_BAG b SUBSET r.carrier ==>
  r.prod.op c (GBAG r.sum b)
  = GBAG r.sum (BAG_IMAGE (\x. r.prod.op c x) b)
Proof
  rpt strip_tac
  \\ irule EQ_TRANS
  \\ qexists_tac`GBAG r.sum b * c`
  \\ `AbelianMonoid r.sum`
  by metis_tac[Ring_def, AbelianMonoid_def, AbelianGroup_def, Group_def]
  \\ `GBAG r.sum b IN r.carrier`
  by (
    `r.carrier = r.sum.carrier` by metis_tac[ring_carriers]
    \\ pop_assum SUBST1_TAC
    \\ irule GBAG_in_carrier
    \\ simp[] )
  \\ conj_tac >- metis_tac[ring_mult_comm]
  \\ DEP_REWRITE_TAC[MP_CANON ring_mult_lsum]
  \\ simp[]
  \\ AP_THM_TAC \\ AP_TERM_TAC
  \\ irule BAG_IMAGE_CONG
  \\ simp[]
  \\ fs[SUBSET_DEF]
  \\ metis_tac[ring_mult_comm]
QED

Theorem ring_mult_sum_image:
  Ring r /\ FINITE s1 /\ FINITE s2 /\ IMAGE f1 s1 SUBSET r.carrier /\ IMAGE f2 s2 SUBSET r.carrier ==>
  r.prod.op (GBAG r.sum (BAG_IMAGE f1 (BAG_OF_SET s1)))
            (GBAG r.sum (BAG_IMAGE f2 (BAG_OF_SET s2))) =
  GBAG r.sum (BAG_IMAGE (\(x1,x2). r.prod.op (f1 x1) (f2 x2)) (BAG_OF_SET (s1 CROSS s2)))
Proof
  strip_tac
  \\ ntac 3 (pop_assum mp_tac)
  \\ qid_spec_tac`s2`
  \\ pop_assum mp_tac
  \\ qid_spec_tac`s1`
  \\ ho_match_mp_tac FINITE_INDUCT
  \\ `AbelianMonoid r.sum`
  by metis_tac[Ring_def, AbelianMonoid_def, AbelianGroup_def, Group_def]
  \\ rw[]
  >- (
    irule ring_mult_lzero
    \\ simp[]
    \\ `r.carrier = r.sum.carrier` by metis_tac[ring_carriers]
    \\ pop_assum SUBST1_TAC
    \\ irule GBAG_in_carrier
    \\ simp[] )
  \\ simp[BAG_OF_SET_INSERT_NON_ELEMENT]
  \\ DEP_REWRITE_TAC[GITBAG_INSERT_THM]
  \\ simp[]
  \\ simp[Once CROSS_INSERT_LEFT]
  \\ DEP_REWRITE_TAC[BAG_OF_SET_DISJOINT_UNION]
  \\ conj_tac >- simp[IN_DISJOINT]
  \\ DEP_REWRITE_TAC[BAG_IMAGE_FINITE_UNION]
  \\ simp[]
  \\ DEP_REWRITE_TAC[GBAG_UNION]
  \\ simp[]
  \\ conj_asm1_tac
  >- fs[SUBSET_DEF, PULL_EXISTS, EXISTS_PROD]
  \\ DEP_ONCE_REWRITE_TAC[GITBAG_GBAG]
  \\ simp[]
  \\ DEP_REWRITE_TAC[ring_mult_ladd]
  \\ simp[]
  \\ conj_asm1_tac
  >- (
    conj_tac
    \\ `r.carrier = r.sum.carrier` by metis_tac[ring_carriers]
    \\ pop_assum SUBST1_TAC
    \\ irule GBAG_in_carrier
    \\ simp[] )
  \\ AP_THM_TAC \\ AP_TERM_TAC
  \\ DEP_REWRITE_TAC[MP_CANON ring_mult_rsum]
  \\ simp[GSYM BAG_IMAGE_COMPOSE]
  \\ simp[combinTheory.o_DEF]
  \\ AP_THM_TAC \\ AP_TERM_TAC
  \\ irule EQ_TRANS
  \\ qexists_tac`BAG_IMAGE ((λ(x1,x2). f1 x1 * f2 x2) o (λx2. (e,x2))) (BAG_OF_SET s2)`
  \\ conj_tac
  >- (
    irule BAG_IMAGE_CONG
    \\ simp[FORALL_PROD] )
  \\ simp[BAG_IMAGE_COMPOSE]
  \\ irule BAG_IMAGE_CONG
  \\ simp[]
  \\ DEP_REWRITE_TAC[GSYM BAG_OF_SET_IMAGE_INJ]
  \\ simp[]
  \\ AP_TERM_TAC
  \\ simp[Once EXTENSION, FORALL_PROD]
QED

Theorem poly_eval_GBAG:
  Ring r ==>
  !p. weak p /\ x IN r.carrier ==>
     poly_eval r p x = GBAG r.sum (BAG_IMAGE (\n. r.prod.op (EL n p) (r.prod.exp x n))
                                              (BAG_OF_SET (count (LENGTH p))))
Proof
  strip_tac
  \\ ho_match_mp_tac SNOC_INDUCT
  \\ rw[] \\ fs[weak_snoc]
  \\ simp[weak_eval_snoc]
  \\ rw[COUNT_SUC]
  \\ DEP_REWRITE_TAC[BAG_OF_SET_INSERT_NON_ELEMENT]
  \\ simp[]
  \\ DEP_REWRITE_TAC[GITBAG_INSERT_THM]
  \\ simp[EL_LENGTH_SNOC]
  \\ simp[GSYM CONJ_ASSOC]
  \\ conj_asm1_tac >- metis_tac[Ring_def, AbelianMonoid_def, AbelianGroup_def, Group_def]
  \\ conj_asm1_tac
  >- fs[SUBSET_DEF, PULL_EXISTS, EL_SNOC, weak_every_mem, MEM_EL]
  \\ irule EQ_SYM
  \\ DEP_ONCE_REWRITE_TAC[GITBAG_GBAG]
  \\ simp[]
  \\ qmatch_goalsub_abbrev_tac`a + b = b' + a`
  \\ irule EQ_TRANS
  \\ qexists_tac`a + b'`
  \\ reverse conj_tac >- (
    imp_res_tac AbelianMonoid_def
    \\ first_x_assum irule
    \\ conj_tac >- simp[Abbr`a`]
    \\ qunabbrev_tac`b'`
    \\ irule GBAG_in_carrier
    \\ simp[SUBSET_DEF, PULL_EXISTS]
    \\ fs[weak_every_mem, MEM_EL, PULL_EXISTS] )
  \\ AP_TERM_TAC
  \\ unabbrev_all_tac
  \\ AP_THM_TAC \\ AP_TERM_TAC
  \\ irule BAG_IMAGE_CONG
  \\ simp[EL_SNOC]
QED

(* end of moving stuff *)

(* A multivariate polynomial is represented as a function assigning each
monomial to a coefficient. A monomial is a bag of indeterminates, representing
a product of the indeterminates each exponentiated by their multiplicity. *)

Type mpoly = ``:'v bag -> 'c``;

Definition rrestrict_def:
  rrestrict r v = if v IN r.carrier then v else r.sum.id
End

Theorem rrestrict_in_carrier[simp]:
  Ring r ==> rrestrict r (p m) ∈ r.carrier
Proof
  rw[rrestrict_def]
QED

Theorem rrestrict_rrestrict[simp]:
  rrestrict r (rrestrict r v) = rrestrict r v
Proof
  rw[rrestrict_def] \\ fs[]
QED

(* The monomials of a polynomial (with coefficients in a ring r) are those
whose coefficients are not zero. *)

Definition monomials_def:
  monomials r p = { t | rrestrict r (p t) <> r.sum.id }
End

(* We only consider polynomials with finitely many terms, and where each term
has finitely many indeterminates. *)

Definition finite_mpoly_def:
  finite_mpoly r p <=>
    FINITE (monomials r p) ∧ (∀m. m ∈ monomials r p ⇒ FINITE_BAG m)
End

(* The support is the set of indeterminates that appear in the polynomial. *)

Definition support_def:
  support r p = BIGUNION (IMAGE SET_OF_BAG (monomials r p))
End

(* The function associated with the polynomial, assuming a mapping from
   indeterminates to the ring of coefficients. *)

Definition mpoly_eval_def:
  mpoly_eval r f p = GBAG r.sum
    (BAG_IMAGE (λt. r.prod.op (rrestrict r (p t)) (GBAG r.prod (BAG_IMAGE f t)))
      (BAG_OF_SET (monomials r p)))
End

(* A multivariate polynomial with a single variable corresponds to a univariate
polynomial. *)

Theorem empty_monomials:
  monomials r p = {} <=> (!x. p x IN r.carrier ==> p x = r.sum.id)
Proof
  rw[monomials_def, Once EXTENSION, rrestrict_def]
  \\ rw[EQ_IMP_THM] \\ metis_tac[]
QED

Theorem empty_support:
  support r p = {} <=> monomials r p SUBSET {{||}}
Proof
  rw[support_def, SUBSET_DEF, IMAGE_EQ_SING]
  \\ metis_tac[NOT_IN_EMPTY]
QED

Definition poly_of_mpoly_def:
  poly_of_mpoly r p =
    if support r p = {} then
    if rrestrict r (p {||}) = r.sum.id then [] else [rrestrict r (p {||})] else
    let v = @v. v IN support r p in
    GENLIST (\n. rrestrict r (p (\w. if w = v then n else 0)))
    (SUC (MAX_SET (IMAGE (\m. m v) (monomials r p))))
End

Theorem support_SING_monomial_form:
  support r p = {v} /\ m IN monomials r p ==>
  m = \x. if x = v then m v else 0
Proof
  rw[support_def]
  \\ fs[Once EXTENSION, PULL_EXISTS]
  \\ simp[Once FUN_EQ_THM] \\ rw[]
  \\ Cases_on`BAG_IN x m`
  \\ fs[BAG_IN, BAG_INN] \\ metis_tac[]
QED

Theorem weak_poly_of_mpoly:
  Ring r ==> weak (poly_of_mpoly r p)
Proof
  rw[weak_every_element, poly_of_mpoly_def, EVERY_GENLIST]
QED

Theorem poly_poly_of_mpoly:
  Ring r /\ FINITE (monomials r p) /\ support r p SUBSET {v} ==>
  poly (poly_of_mpoly r p)
Proof
  rw[poly_def_alt, weak_poly_of_mpoly]
  \\ fs[poly_of_mpoly_def] \\ rw[] \\ fs[]
  \\ fs[GENLIST_LAST]
  \\ `support r p = {v}`
  by ( simp[SET_EQ_SUBSET] \\ Cases_on`support r p` \\ fs[] )
  \\ gs[]
  \\ qmatch_asmsub_abbrev_tac`MAX_SET s`
  \\ Cases_on`s = {}` >- ( fs[Abbr`s`] \\ fs[support_def] )
  \\ `FINITE s` by simp[Abbr`s`]
  \\ `MAX_SET s ∈ s` by metis_tac[MAX_SET_DEF]
  \\ qmatch_asmsub_abbrev_tac`ms ∈ s`
  \\ fs[Abbr`s`]
  \\ qmatch_asmsub_abbrev_tac`rrestrict r (p m') = _`
  \\ `m = m'`
  by (
    imp_res_tac support_SING_monomial_form
    \\ simp[Abbr`m'`] )
  \\ fs[monomials_def]
QED

Definition mpoly_of_poly_def:
  mpoly_of_poly r v p m =
  if SET_OF_BAG m = {v} ∧ m v < LENGTH p
  then rrestrict r (EL (m v) p)
  else if m = {||} /\ 0 < LENGTH p then rrestrict r (EL 0 p)
  else r.sum.id
End

Theorem monomials_mpoly_of_poly:
  Ring r /\ poly p ==>
  monomials r (mpoly_of_poly r v p) =
  IMAGE (λn x. if x = v then n else 0)
  (count (LENGTH p) INTER { n | EL n p <> r.sum.id })
Proof
  rw[monomials_def, Once EXTENSION]
  \\ rw[rrestrict_def] \\ fs[mpoly_of_poly_def]
  \\ pop_assum mp_tac \\ rw[]
  \\ fs[poly_def_alt, SET_OF_BAG_SING]
  \\ rw[] \\ gs[]
  \\ fs[FUN_EQ_THM,EMPTY_BAG] \\ fs[PULL_EXISTS, weak_every_mem]
  \\ rw[rrestrict_def]
  >- metis_tac[]
  >- metis_tac[MEM_EL]
  >- metis_tac[MEM_EL, EL]
  >- metis_tac[MEM_EL, EL]
  >- (
    Cases_on`n < LENGTH p` \\ fs[]
    \\ reverse(Cases_on`n=0`) >- metis_tac[] \\ fs[]
    \\ rw[] \\ fs[])
QED

Theorem support_mpoly_of_poly:
  Ring r /\ poly p ==>
  support r (mpoly_of_poly r v p) = if LENGTH p <= 1 then {} else {v}
Proof
  rw[support_def, monomials_mpoly_of_poly]
  >- (
    Cases_on`p` \\ fs[]
    \\ Cases_on`t` \\ fs[]
    \\ simp[IMAGE_EQ_SING]
    \\ rw[EXTENSION, PULL_EXISTS]
    \\ disj2_tac
    \\ qexists_tac`0` \\ simp[]
    \\ rw[FUN_EQ_THM, EMPTY_BAG] \\ rw[] )
  \\ rw[Once EXTENSION, PULL_EXISTS]
  \\ rw[BAG_IN, BAG_INN]
  \\ Cases_on`x=v`\\ simp[]
  \\ fs[poly_def_alt] \\ rfs[]
  \\ Cases_on`p = []` \\ gs[]
  \\ Cases_on`p` \\ gs[]
  \\ Cases_on`t = []` \\ gs[]
  \\ imp_res_tac LAST_EL_CONS
  \\ qexists_tac`LENGTH t`
  \\ simp[]
  \\ Cases_on`t` \\ fs[]
QED

Theorem poly_of_mpoly_of_poly:
  Ring r ⇒
  ∀p. poly p ⇒ poly_of_mpoly r (mpoly_of_poly r v p) = p
Proof
  rw[]
  \\ simp[poly_of_mpoly_def]
  \\ simp[support_mpoly_of_poly]
  \\ Cases_on`LENGTH p ≤ 1` \\ simp[]
  >- (
    simp[mpoly_of_poly_def]
    \\ Cases_on`p` \\ gs[]
    \\ gs[rrestrict_def]
    \\ Cases_on`t` \\ gs[] )
  \\ simp[monomials_mpoly_of_poly]
  \\ simp[GSYM IMAGE_COMPOSE]
  \\ simp[combinTheory.o_DEF]
  \\ qmatch_goalsub_abbrev_tac`MAX_SET s`
  \\ `LENGTH p - 1 ∈ s`
  by (
    simp[Abbr`s`]
    \\ fs[poly_def_alt]
    \\ Cases_on`p = []` \\ gs[]
    \\ imp_res_tac LAST_EL
    \\ gs[arithmeticTheory.PRE_SUB1] )
  \\ `FINITE s` by simp[Abbr`s`]
  \\ `LENGTH p - 1 ≤ MAX_SET s` by metis_tac[X_LE_MAX_SET]
  \\ `s <> {}` by (strip_tac \\ fs[])
  \\ `MAX_SET s ∈ s` by metis_tac[MAX_SET_DEF]
  \\ `MAX_SET s < LENGTH p` by fs[Abbr`s`]
  \\ `MAX_SET s = LENGTH p - 1` by gs[]
  \\ `0 < LENGTH p` by gs[]
  \\ simp[arithmeticTheory.ADD1]
  \\ simp[LIST_EQ_REWRITE]
  \\ qx_gen_tac`n` \\ strip_tac
  \\ simp[mpoly_of_poly_def]
  \\ simp[SET_OF_BAG_SING, Once FUN_EQ_THM]
  \\ Cases_on`n = 0`
  >- (
    simp[Once FUN_EQ_THM, EMPTY_BAG]
    \\ simp[rrestrict_def] \\ rw[]
    \\ gs[poly_def_alt, weak_every_mem]
    \\ Cases_on`p` \\ gs[] )
  \\ reverse IF_CASES_TAC
  >- ( fs[] \\ metis_tac[] )
  \\ simp[]
  \\ simp[rrestrict_def]
  \\ gs[poly_def_alt, weak_every_mem]
  \\ metis_tac[MEM_EL]
QED

Definition mpoly_def:
  mpoly r p <=> IMAGE p UNIV ⊆ r.carrier ∧ FINITE (monomials r p)
End

Theorem mpoly_of_poly_of_mpoly:
  Ring r ∧ mpoly r p ∧ support r p ⊆ {v} ⇒
  mpoly_of_poly r v (poly_of_mpoly r p) = p
Proof
  rw[mpoly_def]
  \\ simp[poly_of_mpoly_def]
  \\ IF_CASES_TAC
  >- (
    IF_CASES_TAC
    >- (
      rw[mpoly_of_poly_def, Once FUN_EQ_THM]
      \\ fs[rrestrict_def, empty_support, SUBSET_DEF, PULL_EXISTS] \\ gs[]
      \\ gs[monomials_def, rrestrict_def]
      \\ metis_tac[] )
    \\ rw[mpoly_of_poly_def, Once FUN_EQ_THM]
    \\ fs[empty_support, SUBSET_DEF, PULL_EXISTS]
    \\ simp[SET_OF_BAG_SING]
    \\ rw[] \\ gs[EMPTY_BAG]
    \\ gs[FUN_EQ_THM, monomials_def, rrestrict_def]
    \\ metis_tac[] )
  \\ SELECT_ELIM_TAC
  \\ conj_tac >- metis_tac[pred_setTheory.MEMBER_NOT_EMPTY]
  \\ rpt strip_tac
  \\ `support r p = {v}`
  by (
    simp[SET_EQ_SUBSET]
    \\ fs[SUBSET_DEF]
    \\ metis_tac[] )
  \\ imp_res_tac support_SING_monomial_form
  \\ gs[SUBSET_DEF, PULL_EXISTS]
  \\ BasicProvers.VAR_EQ_TAC \\ gs[rrestrict_def]
  \\ rw[mpoly_of_poly_def, Once FUN_EQ_THM]
  \\ gs[rrestrict_def]
  \\ qmatch_goalsub_rename_tac`_ = p m`
  \\ Cases_on`m = {||}` \\ gs[]
  >- ( AP_TERM_TAC \\ simp[FUN_EQ_THM, EMPTY_BAG] )
  \\ reverse(Cases_on`m ∈ monomials r p`)
  >- (
    fs[monomials_def]
    \\ gs[rrestrict_def]
    \\ rw[]
    \\ fs[SET_OF_BAG_SING]
    \\ rw[] )
  \\ simp[SET_OF_BAG_SING]
  \\ qmatch_goalsub_abbrev_tac`MAX_SET s`
  \\ `m v ∈ s` by ( simp[Abbr`s`] \\ metis_tac[] )
  \\ `FINITE s` by simp[Abbr`s`]
  \\ `m v ≤ MAX_SET s` by metis_tac[X_LE_MAX_SET]
  \\ simp[]
  \\ res_tac
  \\ first_assum SUBST1_TAC
  \\ simp[FUN_EQ_THM]
  \\ rw[] \\ fs[]
  \\ first_x_assum(qspec_then`m v`mp_tac)
  \\ simp[]
  \\ strip_tac \\ fs[]
  \\ fs[FUN_EQ_THM, EMPTY_BAG]
QED

Theorem BIJ_poly_of_mpoly:
  Ring r ==>
  BIJ (poly_of_mpoly r)
    { p | mpoly r p ∧ support r p ⊆ {v} }
    { p | poly p }
Proof
  rw[BIJ_IFF_INV, mpoly_def]
  >- (irule poly_poly_of_mpoly \\ metis_tac[])
  \\ qexists_tac`mpoly_of_poly r v`
  \\ simp[support_mpoly_of_poly, monomials_mpoly_of_poly]
  \\ conj_tac >- (
    simp[SUBSET_DEF, PULL_EXISTS]
    \\ rw[mpoly_of_poly_def] \\ rw[] )
  \\ metis_tac[mpoly_of_poly_of_mpoly, poly_of_mpoly_of_poly, mpoly_def]
QED

Theorem eval_mpoly_of_poly:
  Ring r /\ poly p /\ f v IN r.carrier ==>
  mpoly_eval r f (mpoly_of_poly r v p) = poly_eval r p (f v)
Proof
  rw[mpoly_eval_def, monomials_mpoly_of_poly]
  \\ DEP_REWRITE_TAC[poly_eval_GBAG]
  \\ conj_tac >- fs[poly_def_alt]
  \\ irule GITBAG_CONG
  \\ simp[PULL_EXISTS, SUBSET_DEF]
  \\ `weak p` by imp_res_tac poly_def_alt
  \\ fs[weak_every_mem, MEM_EL, PULL_EXISTS]
  \\ `AbelianMonoid r.sum` by
  metis_tac[Ring_def, AbelianMonoid_def, AbelianGroup_def, Group_def]
  \\ simp[]
  \\ `∀n. BAG_IMAGE f (λx. if x = v then n else 0) = (λx. if x = f v then n else 0)`
  by (
    rw[BAG_IMAGE_DEF, BAG_FILTER_DEF]
    \\ simp[FUN_EQ_THM]
    \\ gen_tac
    \\ rewrite_tac[GSYM FINITE_SET_OF_BAG]
    \\ qmatch_goalsub_abbrev_tac`SET_OF_BAG b`
    \\ `SET_OF_BAG b ⊆ {v}`
    by (
      rw[SET_OF_BAG, Abbr`b`, SUBSET_DEF, BAG_IN, BAG_INN]
      \\ pop_assum mp_tac \\ rw[] )
    \\ `FINITE {v}` by simp[]
    \\ reverse IF_CASES_TAC >- metis_tac[SUBSET_FINITE]
    \\ Cases_on`b = {||}` \\ gs[]
    >- ( fs[Abbr`b`, EMPTY_BAG, FUN_EQ_THM] \\ metis_tac[] )
    \\ `SET_OF_BAG b = {v}`
    by (
      simp[SET_EQ_SUBSET]
      \\ Cases_on`b` \\ fs[]
      \\ fs[SET_OF_BAG_INSERT] )
    \\ imp_res_tac SET_OF_BAG_SING_CARD
    \\ simp[Abbr`b`]
    \\ rw[] )
  \\ simp[]
  \\ `∀n. GBAG r.prod (λx. if x = f v then n else 0) = f v ** n`
  by (
    Induct \\ rw[]
    >- (
      qmatch_goalsub_abbrev_tac`GITBAG _ eb _ = _`
      \\ `eb = {||}` by simp[Abbr`eb`, FUN_EQ_THM, EMPTY_BAG]
      \\ rw[] )
    \\ rw[]
    \\ qmatch_goalsub_abbrev_tac`GBAG _ bi`
    \\ qmatch_asmsub_abbrev_tac`GBAG _ b = _`
    \\ `bi = BAG_INSERT (f v) b`
    by (
      simp[BAG_INSERT, Abbr`bi`, FUN_EQ_THM]
      \\ rw[Abbr`b`] )
    \\ rw[]
    \\ DEP_REWRITE_TAC[GITBAG_INSERT_THM]
    \\ simp[]
    \\ DEP_ONCE_REWRITE_TAC[GITBAG_GBAG]
    \\ simp[]
    \\ `SET_OF_BAG b ⊆ {f v}`
    by (
      simp[SET_OF_BAG, Abbr`b`, SUBSET_DEF, BAG_IN, BAG_INN]
      \\ rw[] )
    \\ `FINITE {f v}` by simp[]
    \\ `FINITE_BAG b` by metis_tac[FINITE_SET_OF_BAG, SUBSET_FINITE]
    \\ fs[SUBSET_DEF]
    \\ metis_tac[Ring_def])
  \\ simp[]
  \\ gen_tac
  \\ qmatch_goalsub_abbrev_tac`BAG_IMAGE f1 b1 _ = BAG_IMAGE f2 b2 _`
  \\ `∀n. BAG_IN n b2 ==> f2 n = f1 (λx. if x = v then n else 0)`
  by (
    simp[Abbr`b2`]
    \\ simp[Abbr`f1`, Abbr`f2`]
    \\ simp[mpoly_of_poly_def]
    \\ rpt strip_tac
    \\ simp[SET_OF_BAG_SING]
    \\ Cases_on`n = 0` \\ simp[]
    >- (
      rw[FUN_EQ_THM, EMPTY_BAG]
      \\ rw[rrestrict_def]
      \\ metis_tac[EL] )
    \\ rw[FUN_EQ_THM, EMPTY_BAG]
    \\ reverse(rw[rrestrict_def])
    >- (Cases_on`p` \\ fs[])
    \\ fs[]
    \\ first_x_assum(qspec_then`n`mp_tac)
    \\ simp[] )
  \\ simp[mpoly_of_poly_def, SET_OF_BAG_SING]
  \\ Cases_on`p = []` \\ simp[]
  \\ `0 < LENGTH p` by (Cases_on`p` \\ fs[])
  \\ simp[]
  \\ Cases_on`x = r.sum.id` \\ simp[]
  \\ reverse(Cases_on`∃n. f2 n = x ∧ n < LENGTH p`) \\ simp[]
  >- (
    strip_tac \\ fs[]
    \\ first_x_assum(qspec_then`n`mp_tac)
    \\ simp[Abbr`f2`]
    \\ BasicProvers.VAR_EQ_TAC
    \\ qmatch_goalsub_abbrev_tac`a * b <> a' * b`
    \\ `a = a'`
    by (
      simp[Abbr`a`, Abbr`a'`]
      \\ Cases_on`n = 0` \\ fs[]
      >- (
        simp[FUN_EQ_THM, EMPTY_BAG]
        \\ simp[rrestrict_def]
        \\ metis_tac[EL] )
      \\ simp[FUN_EQ_THM]
      \\ `0 < n` by simp[]
      \\ `rrestrict r (EL n p) = EL n p` by simp[rrestrict_def]
      \\ reverse IF_CASES_TAC >- metis_tac[]
      \\ simp[] )
    \\ simp[] )
  \\ fs[]
  \\ BasicProvers.VAR_EQ_TAC
  \\ irule EQ_TRANS
  \\ qexists_tac`BAG_IMAGE (f1 o (λn x. if x = v then n else 0)) b2 (f2 n)`
  \\ reverse conj_tac
  >- ( AP_THM_TAC \\ irule BAG_IMAGE_CONG \\ simp[] )
  \\ `FINITE_BAG b1 ∧ FINITE_BAG b2` by simp[Abbr`b1`, Abbr`b2`]
  \\ simp[BAG_IMAGE_COMPOSE]
  \\ simp[Once BAG_IMAGE_DEF]
  \\ simp[Once BAG_IMAGE_DEF, SimpRHS]
  \\ AP_TERM_TAC
  \\ simp[BAG_FILTER_DEF]
  \\ simp[FUN_EQ_THM]
  \\ rw[]
  \\ qmatch_goalsub_abbrev_tac`BAG_IMAGE g`
  \\ simp[Abbr`b1`, BAG_OF_SET]
  \\ reverse(rw[])
  >- (
    rw[BAG_IMAGE_DEF, BCARD_0]
    \\ simp[BAG_FILTER_EQ_EMPTY]
    \\ simp[BAG_EVERY]
    \\ simp[Abbr`b2`] \\ fs[]
    \\ rw[]
    \\ strip_tac \\ rw[]
    \\ first_x_assum(qspec_then`e`mp_tac)
    \\ simp[]
    \\ fs[Abbr`f1`, mpoly_of_poly_def, Abbr`g`]
    \\ strip_tac \\ fs[]
    \\ qpat_x_assum`_ = f2 n`mp_tac
    \\ first_x_assum(qspec_then`ARB`kall_tac)
    \\ simp[rrestrict_def]
    \\ rw[]
    \\ fs[FUN_EQ_THM, EMPTY_BAG]
    \\ `e = 0` by metis_tac[]
    \\ fs[] )
  \\ simp[Abbr`b2`]
  \\ simp[BAG_IMAGE_DEF]
  \\ simp[BAG_FILTER_BAG_OF_SET]
  \\ DEP_REWRITE_TAC[BAG_CARD_BAG_OF_SET]
  \\ simp[]
  \\ qmatch_goalsub_abbrev_tac`_ INTER s`
  \\ qmatch_asmsub_rename_tac`EL m p <> _`
  \\ `s = {m}`
  by (
    simp[Abbr`s`, SET_EQ_SUBSET]
    \\ simp[SUBSET_DEF]
    \\ simp[Abbr`g`]
    \\ simp[FUN_EQ_THM]
    \\ rw[]
    \\ first_x_assum(qspec_then`v`mp_tac)
    \\ rw[] )
  \\ `count (LENGTH p) INTER s = {m}`
  by simp[Once EXTENSION]
  \\ simp[]
QED

Theorem eval_poly_of_mpoly:
  Ring r /\ mpoly r p ∧ f v ∈ r.carrier ∧ support r p SUBSET {v} ==>
  poly_eval r (poly_of_mpoly r p) (f v) = mpoly_eval r f p
Proof
  rpt strip_tac
  \\ drule mpoly_of_poly_of_mpoly
  \\ disch_then drule
  \\ disch_then drule
  \\ strip_tac
  \\ irule EQ_TRANS
  \\ qmatch_asmsub_abbrev_tac`q = p`
  \\ qexists_tac`mpoly_eval r f q`
  \\ reverse conj_tac >- simp[]
  \\ qunabbrev_tac`q`
  \\ DEP_REWRITE_TAC[eval_mpoly_of_poly]
  \\ simp[]
  \\ irule poly_poly_of_mpoly
  \\ metis_tac[mpoly_def ]
QED

(* Addition of polynomials *)

Definition mpoly_add_def:
  mpoly_add r p1 p2 t = r.sum.op (rrestrict r (p1 t)) (rrestrict r (p2 t))
End

Theorem rrestrict_mpoly_add[simp]:
  Ring r ⇒
  rrestrict r (mpoly_add r p1 p2 t) = r.sum.op (rrestrict r (p1 t)) (rrestrict r (p2 t))
Proof
  rewrite_tac[rrestrict_def]
  \\ strip_tac
  \\ rpt IF_CASES_TAC
  \\ gs[mpoly_add_def]
  \\ rw[rrestrict_def]
QED

Theorem monomials_mpoly_add:
  Ring r ==>
  monomials r (mpoly_add r p1 p2) =
    (monomials r p1 ∪ monomials r p2) DIFF
      { m | r.sum.op (rrestrict r (p1 m)) (rrestrict r (p2 m)) = r.sum.id }
Proof
  rw[monomials_def, rrestrict_def, mpoly_add_def]
  \\ rw[Once SET_EQ_SUBSET, SUBSET_DEF]
  \\ fs[] \\ rw[] \\ gs[]
QED

Theorem support_mpoly_add_SUBSET:
  Ring r ==> support r (mpoly_add r p q) SUBSET support r p UNION support r q
Proof
  rw[support_def, SUBSET_DEF, PULL_EXISTS, monomials_mpoly_add]
  \\ metis_tac[]
QED

Theorem mpoly_mpoly_add:
  Ring r /\ FINITE (monomials r p) /\ FINITE (monomials r q) ==>
  mpoly r (mpoly_add r p q)
Proof
  rw[mpoly_def, monomials_mpoly_add]
  \\ rw[SUBSET_DEF, mpoly_add_def]
  \\ irule ring_add_element
  \\ simp[]
QED

Theorem mpoly_eval_mpoly_add:
  Ring r ∧ finite_mpoly r p1 ∧ finite_mpoly r p2 ∧
  (∀x::(support r p1 ∪ support r p2). f x ∈ R) ⇒
  mpoly_eval r f (mpoly_add r p1 p2) = mpoly_eval r f p1 + mpoly_eval r f p2
Proof
  rw[mpoly_eval_def, monomials_mpoly_add, RES_FORALL_THM]
  \\ rw[mpoly_add_def]
  \\ qmatch_goalsub_abbrev_tac`GBAG r.sum (BAG_IMAGE f1 _) + GBAG r.sum (BAG_IMAGE f2 _)`
  \\ qmatch_goalsub_abbrev_tac`_ DIFF tz`
  \\ simp[BAG_OF_SET_DIFF]
  \\ qmatch_goalsub_abbrev_tac`BAG_FILTER (COMPL tz) t12`
  \\ qmatch_goalsub_abbrev_tac`BAG_IMAGE f12`
  \\ `FINITE_BAG t12` by gs[Abbr`t12`, finite_mpoly_def]
  \\ `AbelianMonoid r.sum ∧ AbelianMonoid r.prod` by
  metis_tac[Ring_def, AbelianMonoid_def, AbelianGroup_def, Group_def]
  \\ `∀t. FINITE_BAG t ∧ IMAGE f (SET_OF_BAG t) ⊆ R ⇒ GBAG r.prod (BAG_IMAGE f t) ∈ R`
  by (
    rpt strip_tac
    \\ `r.prod.carrier = r.carrier` by metis_tac[ring_carriers]
    \\ first_assum (SUBST1_TAC o SYM)
    \\ irule GBAG_in_carrier
    \\ fs[SUBSET_DEF, PULL_EXISTS] )
  \\ `∀t. BAG_IN t t12 ⇒ GBAG r.prod (BAG_IMAGE f t) ∈ R`
  by (
    rpt strip_tac
    \\ first_x_assum irule
    \\ gs[finite_mpoly_def, Abbr`t12`, SUBSET_DEF, PULL_EXISTS, support_def]
    \\ metis_tac[] )
  \\ `GBAG r.sum (BAG_IMAGE f12 (BAG_FILTER tz t12)) ∈ R`
  by (
    `r.sum.carrier = r.carrier` by metis_tac[ring_carriers]
    \\ first_assum (SUBST1_TAC o SYM)
    \\ irule GBAG_in_carrier
    \\ simp[SUBSET_DEF, PULL_EXISTS]
    \\ simp[Abbr`f12`] \\ simp[Abbr`f1`, Abbr`f2`])
  \\ `GBAG r.sum (BAG_IMAGE f12 (BAG_FILTER tz t12)) = #0`
  by (
    irule IMP_GBAG_EQ_ID
    \\ simp[BAG_EVERY, PULL_EXISTS, Abbr`tz`, Abbr`f12`]
    \\ rw[Abbr`f1`, Abbr`f2`]
    \\ DEP_REWRITE_TAC[GSYM ring_mult_ladd]
    \\ asm_rewrite_tac[] \\ simp[] )
  \\ qmatch_goalsub_abbrev_tac`s = _`
  \\ `s ∈ R`
  by (
    simp[Abbr`s`]
    \\ `r.sum.carrier = r.carrier` by metis_tac[ring_carriers]
    \\ first_assum (SUBST1_TAC o SYM)
    \\ irule GBAG_in_carrier
    \\ simp[SUBSET_DEF, PULL_EXISTS]
    \\ simp[Abbr`f12`, Abbr`f1`, Abbr`f2`] )
  \\ `s = s + #0` by simp[]
  \\ pop_assum SUBST1_TAC
  \\ qunabbrev_tac`s`
  \\ qpat_x_assum`_ = #0` (SUBST1_TAC o SYM)
  \\ DEP_ONCE_REWRITE_TAC[GSYM GITBAG_UNION]
  \\ conj_asm1_tac
  >- (
    simp[]
    \\ gs[SUBSET_DEF, PULL_EXISTS]
    \\ simp[Abbr`f12`, Abbr`f1`, Abbr`f2`] )
  \\ DEP_REWRITE_TAC[GSYM BAG_IMAGE_FINITE_UNION]
  \\ conj_asm1_tac >- simp[]
  \\ REWRITE_TAC[BAG_FILTER_SPLIT]
  \\ qmatch_goalsub_abbrev_tac`_ = (GITBAG _ _ zz) + _`
  \\ `zz = r.sum.id`
  by (
    qunabbrev_tac`zz`
    \\ irule IMP_GBAG_EQ_ID
    \\ simp[BAG_EVERY, PULL_EXISTS]
    \\ simp[Abbr`tz`, Abbr`f12`]
    \\ simp[Abbr`f1`, Abbr`f2`]
    \\ rpt strip_tac
    \\ DEP_REWRITE_TAC[GSYM ring_mult_ladd]
    \\ asm_rewrite_tac[] \\ simp[] )
  \\ simp[]
  \\ DEP_REWRITE_TAC[ring_add_rzero]
  \\ simp[]
  \\ conj_asm1_tac
  >- (
    `r.sum.carrier = r.carrier` by metis_tac[ring_carriers]
    \\ first_assum (SUBST1_TAC o SYM)
    \\ irule GBAG_in_carrier
    \\ simp[SUBSET_DEF, PULL_EXISTS]
    \\ simp[Abbr`f12`] \\ simp[Abbr`f1`, Abbr`f2`])
  \\ `∀t. BAG_IN t t12 ==> f12 t = (λx. f1 x + f2 x) t`
  by simp[Abbr`f12`, Abbr`f1`, Abbr`f2`]
  \\ `BAG_IMAGE f12 t12 = BAG_IMAGE (λx. f1 x + f2 x) t12`
  by ( irule BAG_IMAGE_CONG \\ simp[] )
  \\ pop_assum SUBST1_TAC
  \\ DEP_REWRITE_TAC[GITBAG_BAG_IMAGE_op]
  \\ conj_asm1_tac >- fs[SUBSET_DEF, PULL_EXISTS, Abbr`f1`, Abbr`f2`]
  \\ qmatch_goalsub_abbrev_tac`_ = GBAG _ (BAG_IMAGE _ t1) + GBAG _ (BAG_IMAGE _ t2)`
  \\ `∃b1. BAG_IMAGE f1 t12 = BAG_UNION (BAG_IMAGE f1 t1) b1 ∧ BAG_EVERY ((=) #0) b1
           ∧ FINITE_BAG b1`
  by (
    `t12 = BAG_OF_SET (monomials r p1 ∪ (monomials r p2 DIFF monomials r p1))`
    by simp[Abbr`t12`]
    \\ pop_assum SUBST1_TAC
    \\ DEP_REWRITE_TAC[BAG_OF_SET_DISJOINT_UNION]
    \\ conj_tac >- metis_tac[IN_DISJOINT, IN_DIFF]
    \\ DEP_REWRITE_TAC[BAG_IMAGE_FINITE_UNION]
    \\ simp[] \\ fs[finite_mpoly_def]
    \\ simp[BAG_EVERY, PULL_EXISTS]
    \\ simp[Abbr`f1`]
    \\ fs[monomials_def, Abbr`t12`])
  \\ `∃b2. BAG_IMAGE f2 t12 = BAG_UNION (BAG_IMAGE f2 t2) b2 ∧ BAG_EVERY ((=) #0) b2
           ∧ FINITE_BAG b2`
  by (
    `t12 = BAG_OF_SET (monomials r p2 ∪ (monomials r p1 DIFF monomials r p2))`
    by simp[Abbr`t12`, UNION_COMM]
    \\ pop_assum SUBST1_TAC
    \\ DEP_REWRITE_TAC[BAG_OF_SET_DISJOINT_UNION]
    \\ conj_tac >- metis_tac[IN_DISJOINT, IN_DIFF]
    \\ DEP_REWRITE_TAC[BAG_IMAGE_FINITE_UNION]
    \\ simp[] \\ fs[finite_mpoly_def]
    \\ simp[BAG_EVERY, PULL_EXISTS]
    \\ simp[Abbr`f2`]
    \\ fs[monomials_def, Abbr`t12`])
  \\ simp[Abbr`t12`]
  \\ DEP_REWRITE_TAC[GBAG_UNION]
  \\ conj_asm1_tac
  >- (
    gs[Abbr`t1`,Abbr`t2`]
    \\ gs[SUBSET_DEF,BAG_EVERY]
    \\ metis_tac[ring_zero_element] )
  \\ `GBAG r.sum b1 = #0 ∧ GBAG r.sum b2 = #0`
  by ( conj_tac \\ irule IMP_GBAG_EQ_ID \\ simp[] )
  \\ simp[]
  \\ DEP_REWRITE_TAC[ring_add_rzero]
  \\ gs[]
  \\ `r.sum.carrier = r.carrier` by metis_tac[ring_carriers]
  \\ first_assum (SUBST1_TAC o SYM)
  \\ conj_tac \\ irule GBAG_in_carrier
  \\ simp[SUBSET_DEF, PULL_EXISTS, Abbr`t1`, Abbr`t2`, Abbr`f1`, Abbr`f2`]
QED

Theorem mpoly_add_assoc:
  Ring r ==>
  mpoly_add r (mpoly_add r x y) z =
  mpoly_add r x (mpoly_add r y z)
Proof
  rw[mpoly_add_def, FUN_EQ_THM]
  \\ irule ring_add_assoc
  \\ rw[]
QED

Theorem monomials_zero[simp]:
  monomials r (K r.sum.id) = {}
Proof
  rw[monomials_def, EXTENSION]
  \\ rw[rrestrict_def]
QED

Theorem support_zero[simp]:
  support r (K r.sum.id) = {}
Proof
  rw[empty_support]
QED

Theorem mpoly_zero[simp]:
  Ring r ==> mpoly r (K r.sum.id)
Proof
  rw[mpoly_def] \\ rw[SUBSET_DEF]
QED

Theorem mpoly_add_zero:
  Ring r /\ mpoly r p ==>
  mpoly_add r (K r.sum.id) p = p
Proof
  rw[FUN_EQ_THM, mpoly_add_def]
  \\ rw[rrestrict_def]
  \\ fs[mpoly_def, SUBSET_DEF, PULL_EXISTS]
  \\ metis_tac[]
QED

Definition mpoly_neg_def:
  mpoly_neg r p m = r.sum.inv (rrestrict r (p m))
End

Theorem monomials_mpoly_neg[simp]:
  Ring r ==> monomials r (mpoly_neg r p) = monomials r p
Proof
  rw[monomials_def, EXTENSION]
  \\ rw[mpoly_neg_def]
  \\ rw[rrestrict_def]
QED

Theorem support_mpoly_neg[simp]:
  Ring r ==> support r (mpoly_neg r p) = support r p
Proof
  rw[support_def]
QED

Theorem mpoly_mpoly_neg[simp]:
  Ring r /\ mpoly r p ==> mpoly r (mpoly_neg r p)
Proof
  rw[mpoly_def, mpoly_neg_def, SUBSET_DEF, PULL_EXISTS]
QED

Theorem mpoly_add_neg:
  Ring r ==>
  mpoly_add r (mpoly_neg r p) p = K r.sum.id
Proof
  rw[FUN_EQ_THM, mpoly_add_def, mpoly_neg_def]
  \\ rw[rrestrict_def]
QED

Theorem mpoly_add_comm:
  Ring r ==> mpoly_add r p q = mpoly_add r q p
Proof
  rw[FUN_EQ_THM, mpoly_add_def]
  \\ irule ring_add_comm
  \\ rw[]
QED

(* Multiplication of polynomials *)

Definition mpoly_mul_def:
  mpoly_mul r p1 p2 m =
    GBAG r.sum (BAG_IMAGE (λ(m1,m2). r.prod.op (rrestrict r (p1 m1)) (rrestrict r (p2 m2)))
                   (BAG_OF_SET { (m1,m2) | BAG_UNION m1 m2 = m ∧
                                           m1 ∈ monomials r p1 ∧
                                           m2 ∈ monomials r p2 }))
End

Theorem monomials_mpoly_mul_SUBSET:
  Ring r ==>
  monomials r (mpoly_mul r p1 p2) ⊆
  IMAGE (UNCURRY BAG_UNION) (monomials r p1 × monomials r p2)
Proof
  rw[monomials_def, SUBSET_DEF, EXISTS_PROD]
  \\ pop_assum mp_tac
  \\ simp[mpoly_mul_def, Once rrestrict_def]
  \\ rw[]
  \\ qmatch_asmsub_abbrev_tac`GBAG _ b <> _`
  \\ `AbelianMonoid r.sum`
  by metis_tac[Ring_def, AbelianGroup_def, Group_def, AbelianMonoid_def]
  \\ `¬BAG_EVERY ($= #0) b`
  by (
    drule IMP_GBAG_EQ_ID
    \\ disch_then(qspec_then`b`(irule o CONTRAPOS))
    \\ simp[] )
  \\ fs[BAG_EVERY,Abbr`b`]
  \\ imp_res_tac BAG_IN_BAG_IMAGE_IMP
  \\ fs[] \\ rw[] \\ fs[]
  \\ qexistsl_tac[`m1`,`m2`]
  \\ simp[]
  \\ CCONTR_TAC \\ gs[]
QED

Theorem support_mpoly_mul_SUBSET:
  Ring r ==>
  support r (mpoly_mul r p q) SUBSET support r p UNION support r q
Proof
  rw[support_def]
  \\ imp_res_tac monomials_mpoly_mul_SUBSET
  \\ fs[SUBSET_DEF, PULL_EXISTS, EXISTS_PROD]
  \\ metis_tac[BAG_IN_BAG_UNION]
QED

Theorem mpoly_mul_in_carrier:
  Ring r /\ FINITE (monomials r p1) /\ FINITE (monomials r p2)
  ==> mpoly_mul r p1 p2 m ∈ r.carrier
Proof
  strip_tac
  \\ rw[mpoly_mul_def]
  \\ `r.carrier = r.sum.carrier` by metis_tac[ring_carriers]
  \\ pop_assum SUBST1_TAC
  \\ irule GBAG_in_carrier
  \\ simp[SUBSET_DEF]
  \\ conj_asm1_tac >- metis_tac[Ring_def, AbelianGroup_def, Group_def, AbelianMonoid_def]
  \\ reverse conj_tac
  >- (
    rw[]
    \\ imp_res_tac BAG_IN_BAG_IMAGE_IMP
    \\ fs[] \\ rw[] )
  \\ irule BAG_IMAGE_FINITE
  \\ simp[]
  \\ irule SUBSET_FINITE
  \\ qexists_tac`monomials r p1 × monomials r p2`
  \\ simp[SUBSET_DEF, PULL_EXISTS]
QED

Theorem mpoly_mul_BAG_FILTER_cross:
  mpoly_mul r p1 p2 m =
  GBAG r.sum (BAG_IMAGE (λ(m1,m2). r.prod.op (rrestrict r (p1 m1)) (rrestrict r (p2 m2)))
                (BAG_FILTER (((=) m) o UNCURRY BAG_UNION)
                  (BAG_OF_SET (monomials r p1 × monomials r p2))))
Proof
  rw[mpoly_mul_def]
  \\ AP_THM_TAC \\ AP_TERM_TAC
  \\ AP_TERM_TAC
  \\ simp[BAG_FILTER_BAG_OF_SET]
  \\ AP_TERM_TAC
  \\ simp[Once EXTENSION, FORALL_PROD]
  \\ metis_tac[]
QED

Theorem mpoly_eval_mpoly_mul:
  Ring r /\ finite_mpoly r p1 /\ finite_mpoly r p2 /\
  (!x::support r p1 ∪ support r p2. f x IN r.carrier) ==>
  mpoly_eval r f (mpoly_mul r p1 p2) =
  r.prod.op (mpoly_eval r f p1) (mpoly_eval r f p2)
Proof
  rw[mpoly_eval_def]
  \\ qmatch_goalsub_abbrev_tac`BAG_IMAGE g (BAG_OF_SET mp)`
  \\ mp_tac monomials_mpoly_mul_SUBSET
  \\ simp[] \\ strip_tac
  \\ qmatch_asmsub_abbrev_tac`mp ⊆ mu`
  \\ `mu = mp UNION (mu DIFF mp)` by metis_tac[UNION_DIFF_EQ, SUBSET_UNION_ABSORPTION]
  \\ `AbelianMonoid r.sum` by PROVE_TAC[Ring_def, AbelianGroup_def,
                                        AbelianMonoid_def, Group_def]
  \\ `AbelianMonoid r.prod` by PROVE_TAC[Ring_def]
  \\ `FINITE mu` by fs[finite_mpoly_def, Abbr`mu`]
  \\ `FINITE mp` by metis_tac[SUBSET_FINITE]
  \\ `∀t. FINITE_BAG t /\ SET_OF_BAG (BAG_IMAGE f t) ⊆ r.carrier
          ⇒ GBAG r.prod (BAG_IMAGE f t) ∈ r.carrier`
  by (
    rpt strip_tac
    \\ `r.carrier = r.prod.carrier` by metis_tac[ring_carriers]
    \\ pop_assum SUBST_ALL_TAC
    \\ irule GBAG_in_carrier
    \\ simp[] )
  \\ `∀t. t ∈ mu ⇒ FINITE_BAG t ∧ SET_OF_BAG (BAG_IMAGE f t) ⊆ r.carrier`
  by (
    simp[Abbr`mu`, PULL_EXISTS, FORALL_PROD]
    \\ fs[finite_mpoly_def]
    \\ fs[SUBSET_DEF, RES_FORALL_THM, PULL_EXISTS, support_def]
    \\ metis_tac[] )
  \\ `∀s. s ⊆ mu ⇒ IMAGE g s ⊆ r.carrier`
  by (
    rpt strip_tac
    \\ simp[SUBSET_DEF, PULL_EXISTS, Abbr`g`]
    \\ rfs[] \\ rw[]
    \\ `GBAG r.prod (BAG_IMAGE f t) ∈ r.carrier` suffices_by rw[]
    \\ first_x_assum irule
    \\ fs[SUBSET_DEF, PULL_EXISTS]
    \\ metis_tac[] )
  \\ `∀s. s ⊆ mu ⇒ GBAG r.sum (BAG_IMAGE g (BAG_OF_SET s)) ∈ r.carrier`
  by (
    rpt strip_tac
    \\ `r.carrier = r.sum.carrier` by metis_tac[ring_carriers]
    \\ pop_assum SUBST_ALL_TAC
    \\ irule GBAG_in_carrier
    \\ `FINITE s` by metis_tac[SUBSET_FINITE]
    \\ rfs[] )
  \\ `GBAG r.sum (BAG_IMAGE g (BAG_OF_SET (mu DIFF mp))) = r.sum.id`
  by (
    irule IMP_GBAG_EQ_ID
    \\ simp[BAG_EVERY, PULL_EXISTS, Abbr`g`]
    \\ simp[Abbr`mp`, monomials_def] )
  \\ `GBAG r.sum (BAG_IMAGE g (BAG_OF_SET mp)) = GBAG r.sum (BAG_IMAGE g (BAG_OF_SET mu))`
  by (
    qmatch_goalsub_abbrev_tac`x = _`
    \\ qmatch_asmsub_abbrev_tac`z = #0`
    \\ irule EQ_TRANS
    \\ qexists_tac`x + z`
    \\ conj_tac >- simp[Abbr`x`]
    \\ qunabbrev_tac`x` \\ qunabbrev_tac`z`
    \\ DEP_REWRITE_TAC[GSYM GBAG_UNION]
    \\ conj_tac >- fs[]
    \\ DEP_REWRITE_TAC[GSYM BAG_IMAGE_FINITE_UNION]
    \\ conj_tac >- fs[]
    \\ rewrite_tac[BAG_OF_SET_DIFF]
    \\ `BAG_OF_SET mp = BAG_FILTER mp (BAG_OF_SET mu)`
    by (
      simp[BAG_FILTER_BAG_OF_SET]
      \\ AP_TERM_TAC
      \\ simp[Once EXTENSION]
      \\ fs[SUBSET_DEF] \\ fs[IN_DEF]
      \\ metis_tac[] )
    \\ pop_assum SUBST1_TAC
    \\ rewrite_tac[BAG_FILTER_SPLIT])
  \\ simp[]
  \\ qpat_x_assum`mu = _`kall_tac
  \\ qunabbrev_tac`mu`
  \\ ntac 2 (pop_assum kall_tac)
  \\ qmatch_goalsub_abbrev_tac`BAG_IMAGE g b`
  \\ `BAG_IMAGE g b = BAG_IMAGE (λm. mpoly_mul r p1 p2 m * GBAG r.prod (BAG_IMAGE f m)) b`
  by (
    irule BAG_IMAGE_CONG
    \\ simp[Abbr`g`]
    \\ simp[rrestrict_def]
    \\ rpt strip_tac
    \\ DEP_REWRITE_TAC[mpoly_mul_in_carrier]
    \\ fs[finite_mpoly_def] )
  \\ pop_assum SUBST_ALL_TAC
  \\ qunabbrev_tac`g`
  \\ simp[mpoly_mul_BAG_FILTER_cross]
  \\ qmatch_goalsub_abbrev_tac`BAG_FILTER _ (BAG_OF_SET p12)`
  \\ qmatch_goalsub_abbrev_tac`BAG_IMAGE ff b`
  \\ `BAG_IMAGE ff b =
      BAG_IMAGE
        (λm. GBAG r.sum
          (BAG_IMAGE (λ(m1,m2). rrestrict r (p1 m1) * rrestrict r (p2 m2) * GBAG r.prod (BAG_IMAGE f (BAG_UNION m1 m2)))
            (BAG_FILTER (((=) m) o UNCURRY BAG_UNION) (BAG_OF_SET p12)))) b`
  by (
    irule BAG_IMAGE_CONG
    \\ simp[Abbr`ff`]
    \\ gen_tac
    \\ simp[Abbr`b`, EXISTS_PROD]
    \\ strip_tac
    \\ qmatch_goalsub_abbrev_tac`r.prod.op (GBAG r.sum bb) c`
    \\ DEP_REWRITE_TAC[MP_CANON ring_mult_lsum]
    \\ fs[Abbr`bb`, Abbr`p12`, finite_mpoly_def, GSYM BAG_IMAGE_COMPOSE]
    \\ conj_asm1_tac
    >- (
      simp[Abbr`c`]
      \\ fs[SUBSET_DEF, PULL_EXISTS, FORALL_PROD]
      \\ `r.carrier = r.prod.carrier` by metis_tac[ring_carriers]
      \\ pop_assum SUBST1_TAC
      \\ irule GBAG_in_carrier
      \\ simp[]
      \\ fs[SUBSET_DEF, PULL_EXISTS, RES_FORALL_THM]
      \\ dsimp[]
      \\ fs[support_def, PULL_EXISTS]
      \\ metis_tac[] )
    \\ AP_THM_TAC
    \\ AP_TERM_TAC
    \\ irule BAG_IMAGE_CONG
    \\ simp[FORALL_PROD]
    \\ simp[Abbr`c`])
  \\ pop_assum SUBST_ALL_TAC
  \\ pop_assum kall_tac
  \\ qmatch_goalsub_abbrev_tac`BAG_IMAGE ff (BAG_FILTER _ _)`
  \\ qmatch_goalsub_abbrev_tac`_ = GBAG r.sum (BAG_IMAGE f1 _) * GBAG r.sum (BAG_IMAGE f2 _)`
  \\ `!P. BAG_IMAGE ff (BAG_FILTER P (BAG_OF_SET p12)) =
          BAG_IMAGE (λ(m1,m2). r.prod.op (f1 m1) (f2 m2)) (BAG_FILTER P (BAG_OF_SET p12))`
  by (
    gen_tac
    \\ irule BAG_IMAGE_CONG
    \\ simp[Abbr`p12`, FORALL_PROD]
    \\ simp[Abbr`ff`, Abbr`f1`, Abbr`f2`]
    \\ rpt strip_tac
    \\ DEP_REWRITE_TAC[BAG_IMAGE_FINITE_UNION]
    \\ fs[finite_mpoly_def]
    \\ DEP_REWRITE_TAC[GBAG_UNION] \\ fs[]
    \\ qmatch_goalsub_abbrev_tac`pp * qq * (rr * ss) = _`
    \\ conj_asm1_tac
    >- (
      fs[SUBSET_DEF, PULL_EXISTS, RES_FORALL_THM]
      \\ fs[support_def, PULL_EXISTS]
      \\ metis_tac[] )
    \\ `rr ∈ r.carrier ∧ ss ∈ r.carrier`
    by ( unabbrev_all_tac \\ simp[]  )
    \\ `pp ∈ r.carrier ∧ qq ∈ r.carrier` by simp[Abbr`pp`,Abbr`qq`]
    \\ fs[AbelianMonoid_def]
    \\ DEP_REWRITE_TAC[monoid_assoc]
    \\ simp[]
    \\ AP_TERM_TAC
    \\ metis_tac[monoid_assoc, ring_carriers]  )
  \\ simp[]
  \\ DEP_REWRITE_TAC[ring_mult_sum_image]
  \\ simp[]
  \\ conj_asm1_tac
  >- (
    simp[Abbr`f1`, Abbr`f2`]
    \\ simp[SUBSET_DEF, PULL_EXISTS]
    \\ fs[finite_mpoly_def]
    \\ `∀t. t ∈ monomials r p1 ∨ t ∈ monomials r p2 ⇒
            IMAGE f (SET_OF_BAG t) SUBSET r.carrier`
    by (
      fs[RES_FORALL_THM, support_def, SUBSET_DEF, PULL_EXISTS]
      \\ metis_tac[] )
    \\ simp[] )
  \\ qmatch_goalsub_abbrev_tac`BAG_IMAGE ft (BAG_OF_SET _)`
  \\ qmatch_goalsub_abbrev_tac`BAG_IMAGE fg b`
  \\ `BAG_IMAGE fg b =
      BAG_IMAGE (λP. GBAG r.sum (BAG_IMAGE ft (BAG_FILTER P (BAG_OF_SET p12))))
                (BAG_IMAGE (λm p. m = UNCURRY BAG_UNION p) b)`
  by (
    DEP_REWRITE_TAC[GSYM BAG_IMAGE_COMPOSE]
    \\ simp[Abbr`b`]
    \\ irule BAG_IMAGE_CONG
    \\ simp[Abbr`fg`, PULL_EXISTS, combinTheory.o_DEF])
  \\ pop_assum SUBST1_TAC
  \\ qunabbrev_tac`fg`
  \\ simp[Abbr`b`]
  \\ DEP_ONCE_REWRITE_TAC[GSYM BAG_OF_SET_IMAGE_INJ]
  \\ simp[PULL_EXISTS]
  \\ simp[Once FUN_EQ_THM]
  \\ irule GBAG_IMAGE_PARTITION
  \\ simp[PULL_EXISTS]
  \\ simp[Abbr`p12`, FORALL_PROD, EXISTS_PROD]
  \\ conj_tac >- metis_tac[]
  \\ fs[SUBSET_DEF, PULL_EXISTS, Abbr`ft`, FORALL_PROD]
QED

Theorem mpoly_mpoly_mul:
  Ring r /\ FINITE (monomials r p) /\ FINITE (monomials r q) ==>
  mpoly r (mpoly_mul r p q)
Proof
  rw[mpoly_def, SUBSET_DEF]
  >- (
    irule mpoly_mul_in_carrier
    \\ simp[] )
  \\ irule SUBSET_FINITE
  \\ imp_res_tac monomials_mpoly_mul_SUBSET
  \\ metis_tac[IMAGE_FINITE, FINITE_CROSS]
QED

Theorem rrestrict_mpoly_mul:
  Ring r /\ FINITE (monomials r p) /\ FINITE (monomials r q) ==>
  rrestrict r ((mpoly_mul r p q) m) = mpoly_mul r p q m
Proof
  rw[rrestrict_def]
  \\ imp_res_tac mpoly_mpoly_mul
  \\ fs[mpoly_def, SUBSET_DEF, PULL_EXISTS]
QED

Theorem mpoly_mul_comm:
  Ring r /\ FINITE (monomials r p) /\ FINITE (monomials r q) ==>
  mpoly_mul r p q = mpoly_mul r q p
Proof
  rw[FUN_EQ_THM]
  \\ rw[mpoly_mul_def]
  \\ qmatch_goalsub_abbrev_tac`BAG_OF_SET s1`
  \\ qmatch_goalsub_abbrev_tac`_ = _ _ (_ _ (BAG_OF_SET s2)) _`
  \\ `s2 = IMAGE (λ(x,y). (y,x)) s1`
  by (
    simp[Abbr`s1`, Abbr`s2`]
    \\ simp[Once EXTENSION, PULL_EXISTS, FORALL_PROD]
    \\ metis_tac[COMM_BAG_UNION] )
  \\ simp[]
  \\ DEP_REWRITE_TAC[BAG_OF_SET_IMAGE_INJ]
  \\ simp[FORALL_PROD]
  \\ DEP_REWRITE_TAC[GSYM BAG_IMAGE_COMPOSE]
  \\ simp[combinTheory.o_DEF, LAMBDA_PROD]
  \\ conj_tac
  >- (
    irule SUBSET_FINITE
    \\ qexists_tac`monomials r p CROSS monomials r q`
    \\ simp[SUBSET_DEF, Abbr`s1`, PULL_EXISTS] )
  \\ AP_THM_TAC \\ AP_TERM_TAC
  \\ AP_THM_TAC \\ AP_TERM_TAC
  \\ rw[FUN_EQ_THM]
  \\ irule ring_mult_comm
  \\ simp[]
QED

Theorem mpoly_mul_assoc:
  Ring r /\ FINITE (monomials r x) /\ FINITE (monomials r y) /\ FINITE (monomials r z) ==>
  mpoly_mul r (mpoly_mul r x y) z =
  mpoly_mul r x (mpoly_mul r y z)
Proof
  strip_tac \\ simp[FUN_EQ_THM]
  \\ qx_gen_tac`m`
  \\ rw[mpoly_mul_def]
  \\ qho_match_abbrev_tac`GBAG r.sum (BAG_IMAGE (λ(m1,m2). f12 m1 * f3 m2) _) = _`
  \\ qho_match_abbrev_tac`_ = GBAG r.sum (BAG_IMAGE (λ(m1,m2). f1 m1 * f23 m2) _)`
  \\ gs[]
  \\ qmatch_goalsub_abbrev_tac`_ _ (_ _ (BAG_OF_SET sxy)) _ = _ _ (_ _ (BAG_OF_SET syz)) _`
  \\ qabbrev_tac`xyz = monomials r x × (monomials r y × monomials r z)`
  \\ qabbrev_tac`mm = xyz INTER {(m1,m2,m3) | BAG_UNION m1 (BAG_UNION m2 m3) = m}`
  \\ `sxy ⊆ IMAGE (λ(m1,m2,m3). (BAG_UNION m1 m2, m3)) mm`
  by (
    simp[Abbr`sxy`, SUBSET_DEF, Abbr`mm`, PULL_EXISTS, Abbr`xyz`]
    \\ rpt strip_tac
    \\ drule monomials_mpoly_mul_SUBSET
    \\ simp[SUBSET_DEF, EXISTS_PROD]
    \\ disch_then drule
    \\ strip_tac \\ rw[]
    \\ metis_tac[ASSOC_BAG_UNION] )
  \\ `syz ⊆ IMAGE (λ(m1,m2,m3). (m1, BAG_UNION m2 m3)) mm`
  by (
    simp[Abbr`syz`, SUBSET_DEF, Abbr`mm`, PULL_EXISTS, Abbr`xyz`]
    \\ rpt strip_tac
    \\ drule monomials_mpoly_mul_SUBSET
    \\ simp[SUBSET_DEF, EXISTS_PROD]
    \\ disch_then drule
    \\ strip_tac \\ rw[]
    \\ metis_tac[ASSOC_BAG_UNION] )
  \\ qmatch_asmsub_abbrev_tac`sxy SUBSET s12`
  \\ qmatch_asmsub_abbrev_tac`syz SUBSET s23`
  \\ `AbelianMonoid r.sum`
  by metis_tac[Ring_def, AbelianMonoid_def, AbelianGroup_def, Group_def]
  \\ `FINITE xyz` by simp[Abbr`xyz`]
  \\ `FINITE mm` by simp[Abbr`mm`]
  \\ `FINITE s12 /\ FINITE s23` by simp[Abbr`s12`, Abbr`s23`]
  \\ `FINITE sxy /\ FINITE syz` by metis_tac[SUBSET_FINITE]
  \\ qmatch_goalsub_abbrev_tac`GBAG r.sum (BAG_IMAGE f12_3 _) =
                               GBAG r.sum (BAG_IMAGE f1_23 _)`
  \\ `GBAG r.sum (BAG_IMAGE f12_3 (BAG_OF_SET (s12 DIFF sxy))) = #0`
  by (
    irule IMP_GBAG_EQ_ID
    \\ simp[BAG_EVERY, PULL_EXISTS]
    \\ simp[Abbr`s12`,Abbr`sxy`, PULL_EXISTS, FORALL_PROD]
    \\ simp[Abbr`f12_3`, Abbr`f3`]
    \\ simp[Abbr`mm`, ASSOC_BAG_UNION]
    \\ simp[monomials_def]
    \\ rpt strip_tac
    \\ simp[Abbr`f12`]
    \\ gs[Abbr`f1`]
    \\ gs[mpoly_mul_def] )
  \\ `GBAG r.sum (BAG_IMAGE f1_23 (BAG_OF_SET (s23 DIFF syz))) = #0`
  by (
    irule IMP_GBAG_EQ_ID
    \\ simp[BAG_EVERY, PULL_EXISTS]
    \\ simp[Abbr`s23`,Abbr`syz`, PULL_EXISTS, FORALL_PROD]
    \\ simp[Abbr`f1_23`, Abbr`f1`]
    \\ simp[Abbr`mm`, ASSOC_BAG_UNION]
    \\ simp[monomials_def]
    \\ rpt strip_tac
    \\ simp[Abbr`f23`]
    \\ gs[Abbr`f3`]
    \\ gs[mpoly_mul_def] )
  \\ `s12 = sxy UNION (s12 DIFF sxy) /\
      s23 = syz UNION (s23 DIFF syz)` by (gs[EXTENSION, SUBSET_DEF] \\ metis_tac[])
  \\ irule EQ_TRANS
  \\ qexists_tac`GBAG r.sum (BAG_IMAGE f12_3 (BAG_OF_SET s12))`
  \\ conj_tac
  >- (
    qpat_x_assum`s12 = _`SUBST1_TAC
    \\ DEP_REWRITE_TAC[BAG_OF_SET_DISJOINT_UNION]
    \\ simp[IN_DISJOINT]
    \\ conj_tac >- metis_tac[]
    \\ DEP_REWRITE_TAC[GBAG_UNION]
    \\ simp[]
    \\ conj_asm1_tac
    >- simp[SUBSET_DEF, PULL_EXISTS, Abbr`f12_3`, Abbr`f12`, Abbr`f3`, FORALL_PROD]
    \\ irule EQ_SYM
    \\ irule ring_add_rzero
    \\ simp[]
    \\ `r.carrier = r.sum.carrier` by metis_tac[ring_carriers]
    \\ pop_assum SUBST1_TAC
    \\ irule GBAG_in_carrier
    \\ simp[] )
  \\ irule EQ_TRANS
  \\ qexists_tac`GBAG r.sum (BAG_IMAGE f1_23 (BAG_OF_SET s23))`
  \\ reverse conj_tac
  >- (
    qpat_x_assum`s23 = _`SUBST1_TAC
    \\ DEP_REWRITE_TAC[BAG_OF_SET_DISJOINT_UNION]
    \\ simp[IN_DISJOINT]
    \\ conj_tac >- metis_tac[]
    \\ DEP_REWRITE_TAC[GBAG_UNION]
    \\ simp[]
    \\ conj_asm1_tac
    >- simp[SUBSET_DEF, PULL_EXISTS, Abbr`f1_23`, Abbr`f1`, Abbr`f23`, FORALL_PROD]
    \\ irule ring_add_rzero
    \\ simp[]
    \\ `r.carrier = r.sum.carrier` by metis_tac[ring_carriers]
    \\ pop_assum SUBST1_TAC
    \\ irule GBAG_in_carrier
    \\ simp[] )
  \\ ntac 2 (pop_assum kall_tac)
  \\ ntac 2 (pop_assum kall_tac)
  \\ qpat_x_assum`sxy SUBSET _`kall_tac
  \\ qpat_x_assum`syz SUBSET _`kall_tac
  \\ qpat_x_assum`FINITE sxy`kall_tac
  \\ qpat_x_assum`FINITE syz`kall_tac
  \\ map_every qunabbrev_tac[`syz`,`sxy`]
  \\ gs[GSYM mpoly_mul_def, Abbr`f1`,Abbr`f3`]
  \\ gs[rrestrict_mpoly_mul]
  \\ `f1_23 = λ(m1,m2).
        GBAG r.sum (BAG_IMAGE (λ(m3,m4). rrestrict r (x m1) * rrestrict r (y m3) * rrestrict r (z m4))
                              (BAG_OF_SET {(m5,m6) | BAG_UNION m5 m6 = m2 ∧
                                                     m5 ∈ monomials r y ∧
                                                     m6 ∈ monomials r z}))`
  by (
    simp[Abbr`f1_23`, Once FUN_EQ_THM]
    \\ simp[Once FUN_EQ_THM]
    \\ simp[Abbr`f23`, mpoly_mul_def]
    \\ rpt strip_tac
    \\ DEP_REWRITE_TAC[MP_CANON ring_mult_rsum]
    \\ DEP_REWRITE_TAC[GSYM BAG_IMAGE_COMPOSE]
    \\ simp[combinTheory.o_DEF, LAMBDA_PROD]
    \\ qmatch_goalsub_abbrev_tac`FINITE s`
    \\ `s ⊆ monomials r y × monomials r z`
    by simp[SUBSET_DEF, PULL_EXISTS, Abbr`s`]
    \\ `FINITE s` by metis_tac[SUBSET_FINITE, FINITE_CROSS]
    \\ simp[SUBSET_DEF, PULL_EXISTS, FORALL_PROD]
    \\ AP_THM_TAC \\ AP_TERM_TAC
    \\ AP_THM_TAC \\ AP_TERM_TAC
    \\ simp[FUN_EQ_THM]
    \\ rpt gen_tac
    \\ irule (GSYM ring_mult_assoc)
    \\ simp[] )
  \\ pop_assum SUBST1_TAC
  \\ `f12_3 = λ(m1,m2).
        GBAG r.sum (BAG_IMAGE (λ(m3,m4). rrestrict r (x m3) * rrestrict r (y m4) * rrestrict r (z m2))
                              (BAG_OF_SET {(m5,m6) | BAG_UNION m5 m6 = m1 ∧
                                                     m5 ∈ monomials r x ∧
                                                     m6 ∈ monomials r y}))`
  by (
    simp[Abbr`f12_3`, Once FUN_EQ_THM]
    \\ simp[Once FUN_EQ_THM]
    \\ simp[Abbr`f12`, mpoly_mul_def]
    \\ rpt strip_tac
    \\ DEP_REWRITE_TAC[MP_CANON ring_mult_lsum]
    \\ DEP_REWRITE_TAC[GSYM BAG_IMAGE_COMPOSE]
    \\ simp[combinTheory.o_DEF, LAMBDA_PROD]
    \\ qmatch_goalsub_abbrev_tac`FINITE s`
    \\ `s ⊆ monomials r x × monomials r y`
    by simp[SUBSET_DEF, PULL_EXISTS, Abbr`s`]
    \\ `FINITE s` by metis_tac[SUBSET_FINITE, FINITE_CROSS]
    \\ simp[SUBSET_DEF, PULL_EXISTS, FORALL_PROD] )
  \\ pop_assum SUBST1_TAC
  \\ ntac 2 (pop_assum kall_tac)
  \\ map_every qunabbrev_tac[`f12`,`f23`]
  \\ irule EQ_TRANS
  \\ qexists_tac`GBAG r.sum (BAG_IMAGE (λP.
       GBAG r.sum (BAG_IMAGE
         (λ(m1,m2,m3). rrestrict r (x m1) * rrestrict r (y m2) * rrestrict r (z m3))
         (BAG_FILTER P (BAG_OF_SET mm))))
           (BAG_OF_SET (IMAGE (λ(m1,m2,m3) (n1,n2,n3). m3 = n3 /\ BAG_UNION m1 m2 = BAG_UNION n1 n2) mm)))`
  \\ conj_tac
  >- (
    qmatch_goalsub_abbrev_tac`_ = GBAG _ (_ _ (BAG_OF_SET ss))`
    \\ `ss = IMAGE (λ(m12,m3) (n1,n2,n3). m3 = n3 ∧ m12 = BAG_UNION n1 n2) s12`
    by (
      simp[Abbr`ss`, Abbr`s12`, GSYM IMAGE_COMPOSE]
      \\ simp[combinTheory.o_DEF, LAMBDA_PROD] )
    \\ simp[Abbr`ss`]
    \\ pop_assum kall_tac
    \\ DEP_REWRITE_TAC[BAG_OF_SET_IMAGE_INJ]
    \\ simp[FORALL_PROD]
    \\ simp[Once FUN_EQ_THM]
    \\ simp[Once FUN_EQ_THM]
    \\ simp[Once FUN_EQ_THM]
    \\ conj_tac
    >- (
      simp[Abbr`s12`, PULL_EXISTS, FORALL_PROD]
      \\ metis_tac[] )
    \\ DEP_REWRITE_TAC[GSYM BAG_IMAGE_COMPOSE]
    \\ simp[combinTheory.o_DEF, LAMBDA_PROD]
    \\ AP_THM_TAC \\ AP_TERM_TAC
    \\ irule BAG_IMAGE_CONG
    \\ simp[FORALL_PROD]
    \\ simp[Abbr`s12`, PULL_EXISTS, FORALL_PROD]
    \\ simp[Abbr`mm`, Abbr`xyz`]
    \\ rpt gen_tac \\ strip_tac
    \\ AP_THM_TAC \\ AP_TERM_TAC
    \\ simp[BAG_FILTER_BAG_OF_SET, LAMBDA_PROD]
    \\ qmatch_goalsub_abbrev_tac`_ _ (BAG_OF_SET s) = BAG_IMAGE fg _`
    \\ irule EQ_TRANS
    \\ qmatch_goalsub_rename_tac`z m3`
    \\ qexists_tac`BAG_IMAGE fg (BAG_OF_SET (IMAGE (λ(m1,m2). (m1,m2,m3)) s))`
    \\ conj_tac
    >- (
      DEP_REWRITE_TAC[BAG_OF_SET_IMAGE_INJ]
      \\ simp[FORALL_PROD]
      \\ DEP_REWRITE_TAC[GSYM BAG_IMAGE_COMPOSE]
      \\ `s ⊆ monomials r x × monomials r y`
      by simp[Abbr`s`,SUBSET_DEF,PULL_EXISTS]
      \\ simp[]
      \\ conj_tac >- metis_tac[SUBSET_FINITE, FINITE_CROSS]
      \\ irule BAG_IMAGE_CONG
      \\ simp[FORALL_PROD, Abbr`fg`] )
    \\ AP_TERM_TAC
    \\ AP_TERM_TAC
    \\ simp[Once EXTENSION, FORALL_PROD, PULL_EXISTS]
    \\ simp[Abbr`s`, PULL_EXISTS]
    \\ metis_tac[ASSOC_BAG_UNION] )
  \\ DEP_REWRITE_TAC[MP_CANON GBAG_IMAGE_PARTITION]
  \\ simp[PULL_EXISTS, FORALL_PROD, EXISTS_PROD]
  \\ simp[SUBSET_DEF, PULL_EXISTS, FORALL_PROD]
  \\ conj_tac >- metis_tac[]
  \\ irule EQ_TRANS
  \\ qexists_tac`GBAG r.sum (BAG_IMAGE (λP.
       GBAG r.sum (BAG_IMAGE
         (λ(m1,m2,m3). rrestrict r (x m1) * rrestrict r (y m2) * rrestrict r (z m3))
         (BAG_FILTER P (BAG_OF_SET mm))))
           (BAG_OF_SET (IMAGE (λ(m1,m2,m3) (n1,n2,n3). m1 = n1 /\ BAG_UNION m2 m3 = BAG_UNION n2 n3) mm)))`
  \\ reverse conj_tac
  >- (
    qmatch_goalsub_abbrev_tac`GBAG _ (_ _ (BAG_OF_SET ss)) = _`
    \\ `ss = IMAGE (λ(m1,m23) (n1,n2,n3). m1 = n1 ∧ m23 = BAG_UNION n2 n3) s23`
    by (
      simp[Abbr`ss`, Abbr`s23`, GSYM IMAGE_COMPOSE]
      \\ simp[combinTheory.o_DEF, LAMBDA_PROD] )
    \\ simp[Abbr`ss`]
    \\ pop_assum kall_tac
    \\ DEP_REWRITE_TAC[BAG_OF_SET_IMAGE_INJ]
    \\ simp[FORALL_PROD]
    \\ simp[Once FUN_EQ_THM]
    \\ simp[Once FUN_EQ_THM]
    \\ simp[Once FUN_EQ_THM]
    \\ conj_tac
    >- (
      simp[Abbr`s23`, PULL_EXISTS, FORALL_PROD]
      \\ metis_tac[] )
    \\ DEP_REWRITE_TAC[GSYM BAG_IMAGE_COMPOSE]
    \\ simp[combinTheory.o_DEF, LAMBDA_PROD]
    \\ AP_THM_TAC \\ AP_TERM_TAC
    \\ irule BAG_IMAGE_CONG
    \\ simp[FORALL_PROD]
    \\ simp[Abbr`s23`, PULL_EXISTS, FORALL_PROD]
    \\ simp[Abbr`mm`, Abbr`xyz`]
    \\ rpt gen_tac \\ strip_tac
    \\ AP_THM_TAC \\ AP_TERM_TAC
    \\ simp[BAG_FILTER_BAG_OF_SET, LAMBDA_PROD]
    \\ qmatch_goalsub_abbrev_tac`BAG_IMAGE fg _ = _ _ (BAG_OF_SET s)`
    \\ irule EQ_TRANS
    \\ qmatch_goalsub_rename_tac`x m1`
    \\ qexists_tac`BAG_IMAGE fg (BAG_OF_SET (IMAGE (λ(m2,m3). (m1,m2,m3)) s))`
    \\ reverse conj_tac
    >- (
      DEP_REWRITE_TAC[BAG_OF_SET_IMAGE_INJ]
      \\ simp[FORALL_PROD]
      \\ DEP_REWRITE_TAC[GSYM BAG_IMAGE_COMPOSE]
      \\ `s ⊆ monomials r y × monomials r z`
      by simp[Abbr`s`,SUBSET_DEF,PULL_EXISTS]
      \\ simp[]
      \\ conj_tac >- metis_tac[SUBSET_FINITE, FINITE_CROSS]
      \\ irule BAG_IMAGE_CONG
      \\ simp[FORALL_PROD, Abbr`fg`] )
    \\ AP_TERM_TAC
    \\ AP_TERM_TAC
    \\ simp[Once EXTENSION, FORALL_PROD, PULL_EXISTS]
    \\ simp[Abbr`s`, PULL_EXISTS]
    \\ metis_tac[ASSOC_BAG_UNION] )
  \\ DEP_REWRITE_TAC[MP_CANON GBAG_IMAGE_PARTITION]
  \\ simp[PULL_EXISTS, FORALL_PROD, EXISTS_PROD]
  \\ simp[SUBSET_DEF, PULL_EXISTS, FORALL_PROD]
  \\ metis_tac[]
QED

Definition mpoly_one_def:
  mpoly_one r m = if m = {||} then r.prod.id else r.sum.id
End

Theorem monomials_mpoly_one:
  Ring r ==> monomials r (mpoly_one r) = if r.sum.id = r.prod.id then {} else {{||}}
Proof
  strip_tac
  \\ qmatch_goalsub_abbrev_tac`COND b`
  \\ rewrite_tac[SET_EQ_SUBSET, SUBSET_DEF]
  \\ Cases_on`b=T` \\ fs[]
  \\ rw[monomials_def, mpoly_one_def]
  \\ rw[rrestrict_def]
QED

Theorem support_mpoly_one[simp]:
  Ring r ==> support r (mpoly_one r) = {}
Proof
  rw[empty_support, monomials_mpoly_one]
QED

Theorem mpoly_mpoly_one[simp]:
  Ring r ==> mpoly r (mpoly_one r)
Proof
  rw[mpoly_def, SUBSET_DEF]
  >- rw[mpoly_one_def]
  \\ rw[monomials_mpoly_one]
QED

Theorem mpoly_mul_one:
  Ring r /\ mpoly r p ==>
  mpoly_mul r (mpoly_one r) p = p /\
  mpoly_mul r p (mpoly_one r) = p
Proof
  strip_tac
  \\ conj_asm1_tac
  >- (
    rw[FUN_EQ_THM]
    \\ rw[mpoly_mul_def, monomials_mpoly_one]
    \\ imp_res_tac ring_one_eq_zero
    \\ gs[SUBSET_DEF, PULL_EXISTS, mpoly_def]
    \\ qmatch_goalsub_abbrev_tac`BAG_OF_SET s`
    \\ `s = if x IN monomials r p then {({||},x)} else {}`
    by ( rw[Abbr`s`, Once EXTENSION] )
    \\ reverse(rw[])
    >- gs[monomials_def, rrestrict_def]
    \\ DEP_REWRITE_TAC[BAG_OF_SET_INSERT_NON_ELEMENT]
    \\ simp[mpoly_one_def]
    \\ simp[rrestrict_def] )
  \\ DEP_ONCE_REWRITE_TAC[mpoly_mul_comm]
  \\ gs[mpoly_def, monomials_mpoly_one]
  \\ rw[]
QED

(* Distributivity *)

Theorem mpoly_mul_add:
  Ring r /\ FINITE (monomials r x) /\ FINITE (monomials r y) /\ FINITE (monomials r z) ==>
  mpoly_mul r x (mpoly_add r y z) =
  mpoly_add r (mpoly_mul r x y) (mpoly_mul r x z)
Proof
  rw[FUN_EQ_THM, mpoly_add_def]
  \\ DEP_REWRITE_TAC[rrestrict_mpoly_mul]
  \\ rw[mpoly_mul_def, monomials_mpoly_add]
  \\ qmatch_goalsub_abbrev_tac`GBAG r.sum (BAG_IMAGE f3 (BAG_OF_SET s3)) =
                               GBAG r.sum (BAG_IMAGE f1 (BAG_OF_SET s1)) +
                               GBAG r.sum (BAG_IMAGE f2 (BAG_OF_SET s2))`
  \\ `FINITE s1 ∧ FINITE s2 ∧ FINITE s3`
  by (
    conj_tac
    >- (
      irule SUBSET_FINITE
      \\ qexists_tac`monomials r x × monomials r y`
      \\ simp[SUBSET_DEF, Abbr`s1`, PULL_EXISTS] )
    \\ conj_tac
    >- (
      irule SUBSET_FINITE
      \\ qexists_tac`monomials r x × monomials r z`
      \\ simp[SUBSET_DEF, Abbr`s2`, PULL_EXISTS] )
    \\ irule SUBSET_FINITE
    \\ qexists_tac`monomials r x × (monomials r y ∪ monomials r z)`
    \\ simp[SUBSET_DEF, Abbr`s3`, PULL_EXISTS] )
  \\ `AbelianMonoid r.sum`
  by metis_tac[Ring_def, AbelianMonoid_def, AbelianGroup_def, Group_def]
  \\ `GBAG r.sum (BAG_IMAGE f1 (BAG_OF_SET s1)) =
      GBAG r.sum (BAG_IMAGE f3 (BAG_OF_SET (s1 DIFF s2))) +
      GBAG r.sum (BAG_IMAGE f1 (BAG_OF_SET (s1 INTER s2)))`
  by (
    `s1 = (s1 DIFF s2) UNION (s1 INTER s2)`
    by ( simp[Once EXTENSION] \\ metis_tac[] )
    \\ pop_assum(fn th => simp[Once th])
    \\ DEP_REWRITE_TAC[BAG_OF_SET_DISJOINT_UNION]
    \\ conj_tac >- (simp[IN_DISJOINT] \\ metis_tac[])
    \\ DEP_REWRITE_TAC[BAG_IMAGE_FINITE_UNION]
    \\ conj_tac >- simp[]
    \\ DEP_REWRITE_TAC[GBAG_UNION]
    \\ simp[]
    \\ conj_asm1_tac >- simp[PULL_EXISTS,SUBSET_DEF, Abbr`f1`, FORALL_PROD]
    \\ AP_THM_TAC \\ AP_TERM_TAC
    \\ AP_THM_TAC \\ AP_TERM_TAC
    \\ irule BAG_IMAGE_CONG
    \\ simp[]
    \\ simp[Abbr`s1`, Abbr`s2`, Abbr`f1`, Abbr`f3`, PULL_EXISTS]
    \\ rpt strip_tac \\ gs[]
    \\ fs[monomials_def] )
  \\ `GBAG r.sum (BAG_IMAGE f2 (BAG_OF_SET s2)) =
      GBAG r.sum (BAG_IMAGE f3 (BAG_OF_SET (s2 DIFF s1))) +
      GBAG r.sum (BAG_IMAGE f2 (BAG_OF_SET (s1 INTER s2)))`
  by (
    `s2 = (s2 DIFF s1) UNION (s1 INTER s2)`
    by ( simp[Once EXTENSION] \\ metis_tac[] )
    \\ pop_assum(fn th => simp[Once th])
    \\ DEP_REWRITE_TAC[BAG_OF_SET_DISJOINT_UNION]
    \\ conj_tac >- (simp[IN_DISJOINT] \\ metis_tac[])
    \\ DEP_REWRITE_TAC[BAG_IMAGE_FINITE_UNION]
    \\ conj_tac >- simp[]
    \\ DEP_REWRITE_TAC[GBAG_UNION]
    \\ simp[]
    \\ conj_asm1_tac >- simp[PULL_EXISTS,SUBSET_DEF, Abbr`f2`, FORALL_PROD]
    \\ AP_THM_TAC \\ AP_TERM_TAC
    \\ AP_THM_TAC \\ AP_TERM_TAC
    \\ irule BAG_IMAGE_CONG
    \\ simp[]
    \\ simp[Abbr`s1`, Abbr`s2`, Abbr`f2`, Abbr`f3`, PULL_EXISTS]
    \\ rpt strip_tac \\ gs[]
    \\ fs[monomials_def] )
  \\ pop_assum SUBST1_TAC
  \\ pop_assum SUBST1_TAC
  \\ qmatch_goalsub_abbrev_tac`(a + b) + (c + d)`
  \\ `!s. FINITE_BAG s ==> GBAG r.sum (BAG_IMAGE f1 s) ∈ r.carrier ∧
          GBAG r.sum (BAG_IMAGE f2 s) ∈ r.carrier ∧
          GBAG r.sum (BAG_IMAGE f3 s) ∈ r.carrier`
  by (
    gen_tac \\ strip_tac
    \\ `r.carrier =r.sum.carrier `by metis_tac[ring_carriers]
    \\ pop_assum SUBST1_TAC
    \\ rpt conj_tac \\ irule GBAG_in_carrier
    \\ simp[]
    \\ simp[PULL_EXISTS,SUBSET_DEF,Abbr`f1`,Abbr`f2`,Abbr`f3`, FORALL_PROD])
  \\ `a ∈ r.carrier /\ b ∈ r.carrier /\ c ∈ r.carrier /\ d ∈ r.carrier`
  by simp[Abbr`a`,Abbr`b`,Abbr`c`,Abbr`d`]
  \\ `(a + b) + (c + d) = (a + c) + (b + d)`
  by (
    simp[ring_add_assoc, ring_add_comm]
    \\ AP_TERM_TAC
    \\ metis_tac[ring_add_assoc, ring_add_comm] )
  \\ pop_assum SUBST1_TAC
  \\ `b + d = GBAG r.sum (BAG_IMAGE f3 (BAG_OF_SET (s1 INTER s2)))`
  by (
    qunabbrev_tac`f3`
    \\ qunabbrev_tac`b` \\ qunabbrev_tac`d`
    \\ qunabbrev_tac`f1` \\ qunabbrev_tac`f2`
    \\ DEP_REWRITE_TAC[GSYM (MP_CANON GITBAG_BAG_IMAGE_op)]
    \\ simp[]
    \\ simp[SUBSET_DEF, PULL_EXISTS, EXISTS_PROD]
    \\ simp[LAMBDA_PROD] )
  \\ pop_assum SUBST1_TAC
  \\ map_every qunabbrev_tac[`b`,`d`]
  \\ map_every qunabbrev_tac[`a`,`c`]
  \\ DEP_REWRITE_TAC[GSYM GBAG_UNION]
  \\ simp[]
  \\ simp[SUBSET_DEF, PULL_EXISTS]
  \\ conj_tac
  >- (
    simp[Abbr`f3`, PULL_EXISTS, EXISTS_PROD, FORALL_PROD]
    \\ dsimp[] )
  \\ DEP_REWRITE_TAC[GSYM BAG_IMAGE_FINITE_UNION]
  \\ conj_tac >- simp[]
  \\ DEP_REWRITE_TAC[GSYM BAG_OF_SET_DISJOINT_UNION]
  \\ conj_tac >- ( simp[IN_DISJOINT] \\ metis_tac[] )
  \\ `s3 = s1 UNION s2 DIFF {(m1,m2) | (m1,m2) | rrestrict r (y m2) + rrestrict r (z m2) = #0}`
  by (
    simp[Abbr`s3`, Abbr`s1`, Abbr`s2`, Once SET_EQ_SUBSET, SUBSET_DEF, PULL_EXISTS]
    \\ simp[FORALL_PROD]
    \\ metis_tac[] )
  \\ simp[Abbr`s3`]
  \\ pop_assum kall_tac
  \\ simp[BAG_OF_SET_DIFF]
  \\ qmatch_goalsub_abbrev_tac`_ = _ _ (BAG_IMAGE _ (BAG_OF_SET s12)) _`
  \\ `s12 = s1 ∪ s2`
  by ( simp[SET_EQ_SUBSET, Abbr`s12`, SUBSET_DEF] )
  \\ pop_assum SUBST1_TAC
  \\ qmatch_goalsub_abbrev_tac`BAG_FILTER s b`
  \\ `BAG_IMAGE f3 b = BAG_IMAGE f3 (BAG_UNION (BAG_FILTER s b) (BAG_FILTER (COMPL s) b))`
  by metis_tac[BAG_FILTER_SPLIT]
  \\ pop_assum SUBST1_TAC
  \\ DEP_REWRITE_TAC[BAG_IMAGE_FINITE_UNION]
  \\ conj_tac >- simp[Abbr`b`]
  \\ DEP_REWRITE_TAC[GBAG_UNION]
  \\ conj_tac
  >- (
    simp[Abbr`b`]
    \\ simp[SUBSET_DEF, PULL_EXISTS, Abbr`f3`, FORALL_PROD] )
  \\ qmatch_goalsub_abbrev_tac`a = a + c`
  \\ `a IN R /\ c IN R`
  by ( simp[Abbr`a`,Abbr`c`] \\ simp[Abbr`b`] )
  \\ `c = #0` suffices_by simp[]
  \\ qunabbrev_tac`c`
  \\ irule IMP_GBAG_EQ_ID
  \\ simp[BAG_EVERY]
  \\ simp[Abbr`b`, PULL_EXISTS]
  \\ simp[Abbr`f3`, Abbr`s`, PULL_EXISTS]
  \\ rpt gen_tac
  \\ DEP_REWRITE_TAC[GSYM ring_mult_radd]
  \\ conj_tac >- simp[]
  \\ rewrite_tac[GSYM AND_IMP_INTRO]
  \\ disch_then SUBST1_TAC
  \\ simp[]
QED

(* Ring of multivariate polynomials over a given support *)

Definition mpoly_ring_def:
  mpoly_ring (r:'a ring) (s:'v set) :('a,'v) mpoly ring =
  let m = { p | mpoly r p /\ support r p ⊆ s } in
    <| carrier := m;
         sum := <| carrier := m; op := mpoly_add r; id := K r.sum.id |>;
         prod := <| carrier := m; op := mpoly_mul r; id := mpoly_one r |> |>
End

Theorem mpoly_add_group:
  Ring r ==> Group (mpoly_ring r s).sum
Proof
  strip_tac
  \\ simp[group_def_alt, mpoly_ring_def]
  \\ conj_tac
  >- (
    rpt gen_tac \\ strip_tac
    \\ imp_res_tac mpoly_def
    \\ simp[mpoly_mpoly_add]
    \\ imp_res_tac support_mpoly_add_SUBSET
    \\ fs[SUBSET_DEF]
    \\ metis_tac[])
  \\ conj_tac >- simp[mpoly_add_assoc]
  \\ conj_tac >- simp[mpoly_add_zero]
  \\ rpt strip_tac
  \\ qexists_tac`mpoly_neg r x`
  \\ simp[mpoly_add_neg]
QED

Theorem mpoly_add_abelian_group:
  Ring r ==> AbelianGroup (mpoly_ring r s).sum
Proof
  rw[AbelianGroup_def, mpoly_add_group]
  \\ fs[mpoly_ring_def]
  \\ simp[mpoly_add_comm]
QED

Theorem mpoly_mul_monoid:
  Ring r ==> Monoid (mpoly_ring r s).prod
Proof
  strip_tac
  \\ rewrite_tac[Monoid_def]
  \\ simp[mpoly_ring_def]
  \\ conj_tac
  >- (
    rpt strip_tac
    >- ( irule mpoly_mpoly_mul \\ fs[mpoly_def] )
    \\ imp_res_tac support_mpoly_mul_SUBSET
    \\ fs[SUBSET_DEF]
    \\ metis_tac[])
  \\ conj_tac >- (
    rpt strip_tac
    \\ irule mpoly_mul_assoc
    \\ fs[mpoly_def])
  \\ rw[mpoly_mul_one]
QED

Theorem mpoly_mul_abelian_monoid:
  Ring r ==> AbelianMonoid (mpoly_ring r s).prod
Proof
  rw[AbelianMonoid_def]
  >- rw[mpoly_mul_monoid]
  \\ fs[mpoly_ring_def]
  \\ irule mpoly_mul_comm
  \\ fs[mpoly_def]
QED

Theorem mpoly_ring:
  Ring r ==> Ring (mpoly_ring r s)
Proof
  strip_tac
  \\ rewrite_tac[Ring_def]
  \\ conj_tac >- simp[mpoly_add_abelian_group]
  \\ conj_tac >- simp[mpoly_mul_abelian_monoid]
  \\ conj_tac >- simp[mpoly_ring_def]
  \\ conj_tac >- simp[mpoly_ring_def]
  \\ rw[mpoly_ring_def]
  \\ irule mpoly_mul_add
  \\ fs[mpoly_def]
QED

val _ = export_theory();