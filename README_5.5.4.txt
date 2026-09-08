COMEDY HOST STUDIO BETA 5.1
PATCH 5.5.4 - CLEAN STABILITY

MUC TIEU
- Quay lai dung kieu cap nhat cua cac ban 5.5.3b -> 5.5.3e.
- KHONG stack cac hotfix 5.5.3f / 5.5.3g / 5.5.3h.
- Khoi phuc engine.py 5.5.3e sach tu backup da duoc tao tren may truoc khi 5.5.3f sua engine.
- Chi sua loi Final Gate V3: neu sau 3 pass van con mot vai hard-repeat, app ghi QA/warning nhung KHONG huy toan bo SRT.

BASE GIU NGUYEN
- Visual Brain / GPU Recovery 5.5.3b
- Safe GPU Auto num_gpu=-1 + main_gpu=0
- StoryFlow
- GoldStyle / Hook / reviewer / comedy
- Anti-Repeat V3 cua 5.5.3e
- US target 10 words/caption
- ~4.08 giay/caption
- gap 0.10s
- Japanese writer
- Vietnamese translation
- cache/resume va full timeline

5.5.4 KHONG LAM
- Khong them helper _antirepeat_last_resort_553f.
- Khong chen function vao cuoi engine.py.
- Khong tim / di chuyen main() hoac Python entry point.
- Khong phu thuoc patch_5_5_3f/g/h.
- Khong doc lai toan bo video chi de sua 1 caption.

CACH CAI
1. DONG HAN Comedy Host Studio.
2. Giai nen ZIP 5.5.4.
3. Chay INSTALL_PATCH.bat.
4. Neu installer bao PASS, mo lai app va chay video test.

CACH INSTALLER HOAT DONG
1. Backup engine hien tai thanh engine.py.before_5.5.4_YYYYMMDD_HHMMSS.
2. Tim file engine.py.bak_5.5.3e_* trong thu muc app.
3. Chi nhan backup neu xac minh dung clean 5.5.3e va KHONG co marker/helper f/g/h.
4. Tao engine 5.5.4 tu clean 5.5.3e.
5. Chi thay fatal abort o Final Gate bang stability continuation.
6. Kiem tra integrity; neu may co Python launcher thi py_compile.
7. Neu loi, engine hien tai truoc 5.5.4 duoc giu/restore an toan.

NEU KHONG TIM THAY BACKUP 5.5.3e
Installer se DUNG va KHONG sua engine.
Hay cai lai goi ComedyHostStudio_Beta51_SRT_Patch_5.5.3e_AntiRepeatV3 mot lan, dong app, sau do chay lai INSTALL_PATCH.bat 5.5.4.

ROLLBACK
Chay RESTORE_BEFORE_5.5.4.bat de khoi phuc backup engine ngay truoc luc cai 5.5.4.

SAU KHI TEST
Gui Vietnamese_Translation.txt + Repeat_QA.json (neu co) de kiem tra chat luong script, repetition va word count.
