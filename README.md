# MEMBER HUB — ระบบลงทะเบียนสมาชิก

เว็บไซต์ลงทะเบียนและจัดการรายชื่อสมาชิก ธีมดำ-ม่วง รองรับมือถือและคอมพิวเตอร์ ใช้ Supabase Auth และ PostgreSQL เป็น backend จริง

## ฟีเจอร์

- สมัครสมาชิกและเข้าสู่ระบบด้วยอีเมล/รหัสผ่าน
- บันทึกชื่อ-นามสกุลและรหัสสมาชิก พร้อมวันที่และเวลาอัตโนมัติ
- สมาชิกดูประวัติการลงทะเบียนของตนเอง
- ผู้ดูแลระบบดู ค้นหา และลบข้อมูลสมาชิกทั้งหมด
- ส่งออกข้อมูลสมาชิกเป็นไฟล์ CSV ซึ่งเปิดด้วย Excel ได้
- Row Level Security (RLS) จำกัดสิทธิ์การอ่านและแก้ไขข้อมูล

## 1. สร้าง Supabase project

1. ไปที่ https://supabase.com/ แล้วสร้าง Project
2. เปิดเมนู **SQL Editor** ใน Supabase
3. เปิดไฟล์ `supabase/schema.sql` ใน Repository นี้ คัดลอกเนื้อหาทั้งหมดไปวาง แล้วกด Run
4. ไปที่ **Project Settings → API** แล้วคัดลอก Project URL และ anon/publishable key

## 2. ตั้งค่าเว็บไซต์

1. ดาวน์โหลดหรือ Clone Repository นี้ลงเครื่อง
2. คัดลอก `config.example.js` แล้วตั้งชื่อไฟล์ใหม่เป็น `config.js`
3. เปิด `config.js` แล้วใส่ค่า Supabase ของ Project:

```js
window.APP_CONFIG = {
  SUPABASE_URL: "https://YOUR-PROJECT.supabase.co",
  SUPABASE_ANON_KEY: "YOUR_SUPABASE_ANON_OR_PUBLISHABLE_KEY"
};
```

4. เปิดเว็บผ่าน local web server (เช่น VS Code Live Server) ไม่ควรเปิด index.html ด้วย file:// โดยตรง

> `config.js` ถูกเพิ่มไว้ใน .gitignore เพื่อไม่ให้เผลอ commit ค่าตั้งค่าในเครื่องลง Repository หากจะ deploy ต้องตั้งค่าไฟล์นี้ใน build/deployment environment หรือสร้างไฟล์ config.js ในขั้นตอน deploy

## 3. ตั้งผู้ดูแลระบบ (Admin)

1. สมัครบัญชีผ่านหน้าเว็บไซต์ตามปกติ
2. เปิด Supabase → SQL Editor
3. รันคำสั่งนี้ โดยเปลี่ยนอีเมลเป็นอีเมลบัญชีของคุณ:

```sql
update public.profiles
set role = 'admin'
where id = (
  select id from auth.users
  where email = 'YOUR_EMAIL@example.com'
);
```

บัญชีใหม่ทุกบัญชีจะมีสิทธิ์ `user` โดยอัตโนมัติ การเพิ่มสิทธิ์ admin ต้องทำจาก Supabase Dashboard/SQL โดยผู้ดูแลฐานข้อมูลเท่านั้น

## 4. Deploy ด้วย GitHub Pages (ทางเลือก)

โปรเจกต์นี้เป็น static frontend จึงสามารถเผยแพร่ด้วย GitHub Pages ได้ แต่ต้องจัดเตรียม `config.js` ที่มี Supabase URL และ anon/publishable key ในขั้นตอน deploy ก่อนเปิดใช้งานจริง อย่าใส่ service_role key ในเว็บไซต์หรือ Repository เด็ดขาด

## โครงสร้างไฟล์

- `index.html` — หน้าเว็บและฟอร์ม
- `styles.css` — ธีมและ responsive layout
- `app.js` — การทำงานของระบบและเชื่อม Supabase
- `config.example.js` — ตัวอย่างค่าตั้งค่า Supabase
- `supabase/schema.sql` — ตาราง, trigger และ RLS policies

## ความปลอดภัย

- ใช้ Supabase Auth สำหรับยืนยันตัวตน
- เปิด RLS สำหรับทุกตารางที่หน้าเว็บเข้าถึง
- ห้ามใช้ `service_role` key ฝั่ง browser
- ควรเปิด Email confirmation และตั้งค่า SMTP/URL redirect ใน Supabase ให้เหมาะกับโดเมนที่ deploy
- ควรตรวจสอบนโยบายและทดสอบสิทธิ์ USER/ADMIN ก่อนใช้กับข้อมูลจริง
