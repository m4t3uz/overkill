with Interfaces;
use Interfaces;
with Interfaces.C;
use Interfaces.C;
with Interfaces.C.Pointers;
with Ada.Strings;
with Ada.Unchecked_Conversion;
with System;
use System;
with System.Address_Image;
with Ada.Text_IO;
use Ada.Text_IO;
with Interfaces.C.Strings;

package body w32 is
   
   --
   -- Constants
   --
   COLOR_BNTFACE : constant := 15;
   
   -- Load image
   IMAGE_BITMAP : constant := 0;
   IMAGE_CURSOR : constant := 2;
   LR_LOADFROMFILE : constant := 16#10#;
   
   -- Window styles
   WS_MINIMIZEBOX : constant := 16#00020000#;
   WS_POPUP : constant := 16#80000000#;
   
   -- Window messages
   WM_CLOSE : constant := 16#0010#;
   WM_ERASEBKGND : constant := 16#0014#;
   WM_SETCURSOR : constant := 16#0020#;
   WM_PAINT : constant := 16#000F#;
   WM_LBUTTONDOWN : constant := 16#0201#;
   WM_LBUTTONUP : constant := 16#0202#;
   WM_MOUSEMOVE : constant := 16#0200#;
   WM_SIZE : constant := 16#0005#;
   WM_SETFOCUS : constant := 16#0007#;
   WM_KILLFOCUS : constant := 16#0008#;
   WM_RBUTTONUP : constant := 16#0205#;
   
   -- GetWindowLongPtr
   GWLP_USERDATA : constant := -21;
   
   -- BitBlt
   SRCCOPY : constant := 16#00CC0020#;
   
   -- RedrawWindow
   RDW_INVALIDATE : constant := 16#1#;
   
   --
   -- Types
   --
   type Null_Record is null record;
   
   type HANDLE is new System.Address;
   type HWND is new System.Address;
   type LPCSTR is new System.Address;
   type HMENU is new System.Address;
   type HINSTANCE is new System.Address;
   type LPVOID is new System.Address;
   type DWORD is new Interfaces.C.unsigned;
   type BOOL is new Interfaces.C.int;
   type UINT is new Interfaces.C.unsigned;
   type ATOM is new System.Address;
   type WNDPROC is new System.Address;
   type HICON is new System.Address;
   type HCURSOR is access all gui.Null_Record;
   type HBITMAP is access gui.Null_Record;
   type HBRUSH is new System.Address;
   type HMODULE is new System.Address;
   type LRESULT is new Interfaces.C.unsigned;
   type WPARAM is new Interfaces.C.unsigned;
   type LPARAM is new Interfaces.C.unsigned;
   type LPMSG is new System.Address;
   type HDC is new System.Address;
   type HGDIOBJ is access all gui.Null_Record;
   type LONG_PTR is access Null_Record;
   
   --
   -- Records
   --
   type POINT is record
      x : LONG;
      y : LONG;
   end record;
   
   type MSG is record
      handle : HWND;
      message : UINT;
      w : WPARAM;
      l : LPARAM;
      time : DWORD;
      pt : POINT;
      lPrivate : DWORD;
   end record;
   
   type WNDCLASSA is record
      style : UINT;
      lpfnWndProc : WNDPROC;
      cbClsExtra : Interfaces.C.int;
      cbWndExtra : Interfaces.C.int;
      instance : HINSTANCE;
      icon : HICON;
      cursor : HCURSOR;
      hbrBackground : HBRUSH;
      lpszMenuName : LPCSTR;
      lpszClassName : LPCSTR;
   end record;
   
   type RECT is record
      left, top, right, bottom : LONG;
   end record;
   
   type PAINTSTRUCT is record
      dc : HDC;
      fErase : BOOL;
      rcPaint : RECT;
      fRestore : BOOL;
      fIncUpdate : BOOL;
      rgbReserved : String(1..32);
   end record;
   
   --
   -- Global variables
   --
   class_name : String := "classic_window";
   current_cursor : HCURSOR;
   mem_dc, bmp_dc : HDC;
   mem_bmp : HBITMAP;
   cur_window : HWND;
   p : PAINTSTRUCT;
   
   --
   -- Functions
   --
   function RegisterClassA(
                           lpWndClass : System.Address
                          ) return ATOM;
   pragma Import (Stdcall, RegisterClassA, "RegisterClassA");
   
   function UnregisterClassA(
                            lpClassName : LPCSTR;
                            instance : HINSTANCE
                            ) return BOOL;
   pragma Import (Stdcall, UnregisterClassA, "UnregisterClassA");
   
   function CreateWindowExA(
                            dwExStyle : DWORD;
                            lpClassName : LPCSTR;
                            lpWindowName : LPCSTR;
                            dwStyle : DWORD;
                            X : Interfaces.C.int;
                            Y : Interfaces.C.int;
                            nWidth: Interfaces.C.int;
                            nHeight : Interfaces.C.int;
                            hWndParent : HWND;
                            menu : HMENU;
                            instance : HINSTANCE;
                            lpParam : access Skin_Callbacks
                           ) return HWND;
   pragma Import (Stdcall, CreateWindowExA, "CreateWindowExA");
   
   function DestroyWindow(handle : HWND) return BOOL;
   pragma Import (Stdcall, DestroyWIndow, "DestroyWindow");
   
   function ShowWindow(handle : HWND; cmd : Interfaces.C.int) return BOOL;
   pragma Import (Stdcall, ShowWindow, "ShowWindow");
   
   SW_HIDE : constant := 0;
   SW_SHOW : constant := 5;
   
   IDI_APPLICATION : constant := 32512;
   
   IDC_ARROW : constant := 32512;
   
   function HWND_To_Window is new Ada.Unchecked_Conversion(HWND, Window);
   function Window_To_HWND is new Ada.Unchecked_Conversion(Window, HWND);
   function MAKEINTRESOURCE is new Ada.Unchecked_Conversion(System.Address, LPCSTR);
   
   function HANDLE_To_Pixmap is new Ada.Unchecked_Conversion(HANDLE, Pixmap);
   function HANDLE_To_Cursor is new Ada.Unchecked_Conversion(HANDLE, Cursor);
   
   function LPCSTR_To_chars_ptr is new Ada.Unchecked_Conversion(LPCSTR, Interfaces.C.Strings.chars_ptr);
   
   function GetModuleHandleA(lpModuleName : LPCSTR) return HMODULE;
   pragma Import (Stdcall, GetModuleHandleA, "GetModuleHandleA");
   
   function LoadIconA(
                     instance : HINSTANCE;
                     lpIconName : LPCSTR
                    ) return HICON;
   pragma Import (Stdcall, LoadIconA, "LoadIconA");
   
   function LoadCursorA(
                       instance : HINSTANCE;
                       lpCursorName : LPCSTR
                      ) return HCURSOR;
   pragma Import (Stdcall, LoadCursorA, "LoadCursorA");
   
   function LoadBitmapA(
                        instance : HINSTANCE;
                        lpBitmapName : LPCSTR
                       ) return HBITMAP;
   pragma Import (Stdcall, LoadBitmapA, "LoadBitmapA");
   
   function LoadImageA(
                       instance : HINSTANCE;
                       name : LPCSTR;
                       imgtype : UINT;
                       cx : Interfaces.C.int;
                       cy : Interfaces.C.int;
                       fuLoad : UINT
                      ) return HANDLE;
   pragma Import (Stdcall, LoadImageA, "LoadImageA");
   
   function GetLastError return DWORD;
   pragma Import (Stdcall, GetLastError, "GetLastError");
   
   FORMAT_MESSAGE_ALLOCATE_BUFFER : constant := 16#00000100#;
   FORMAT_MESSAGE_FROM_SYSTEM : constant := 16#00001000#;
   FORMAT_MESSAGE_IGNORE_INSERTS : constant := 16#00000200#;
   
   function FormatMessageA(
                          dwFlags : DWORD;
                          lpSource : LPVOID;
                          dwMessageId : DWORD;
                          dwLanguageId : DWORD;
                          lpBuffer : out LPCSTR;
                          nSize : DWORD
                         ) return DWORD;
   pragma Import (Stdcall, FormatMessageA, "FormatMessageA");
   
   function MessageBoxA(
                       window : HWND;
                       lpText : LPCSTR;
                       lpCaption : LPCSTR;
                       uType : UINT
                      ) return Interfaces.C.int;
   pragma Import (Stdcall, MessageBoxA, "MessageBoxA");
   
   MB_ICONERROR : constant := 16#00000010#;
   MB_OK : constant := 16#00000000#;
   
   function DefWindowProcA(
                          handle : HWND;
                          uMsg : UINT;
                          w : WPARAM;
                          l : LPARAM
                         ) return LRESULT;
   pragma Import (Stdcall, DefWindowProcA, "DefWindowProcA");
   
   function GetMessageA(
                       msg : LPMSG;
                       handle : HWND;
                       wMsgFilterMin : UINT;
                       wMsgFilterMax : UINT
                      ) return BOOL;
   pragma Import (Stdcall, GetMessageA, "GetMessageA");
   
   function TranslateMessage(msg : LPMSG) return BOOL;
   pragma Import (Stdcall, TranslateMessage, "TranslateMessage");
   
   function DispatchMessageA(msg : LPMSG) return LRESULT;
   pragma Import (Stdcall, DispatchMessageA, "DispatchMessageA");
   
   procedure PostQuitMessage(nExitCode : Interfaces.C.int);
   pragma Import (Stdcall, PostQuitMessage, "PostQuitMessage");
   
   function SetCursor(cursor : HCURSOR) return HCURSOR;
   pragma Import (Stdcall, SetCursor, "SetCursor");
   
   function CreateCompatibleDC(dc : HDC) return HDC;
   pragma Import (Stdcall, CreateCompatibleDC, "CreateCompatibleDC");
   
   function DeleteDC(dc : HDC) return BOOL;
   pragma Import (Stdcall, DeleteDC, "DeleteDC");
   
   function RedrawWindow
     (h : Window;
      lprcUpdate : System.Address;
      hrgnUpdate : System.Address;
      flags : UINT)
      return BOOL;
   pragma Import (Stdcall, RedrawWindow, "RedrawWindow");
   
   function SetWindowLongPtrA(
                              win : HWND;
                              nIndex : Interfaces.C.int;
                              dwNewLong : access Skin_Callbacks
                             ) return LONG_PTR;
   pragma Import (Stdcall, SetWindowLongPtrA, "SetWindowLongPtrA");
   
   function GetWindowLongPtrA(
                              window : HWND;
                              nIndex : Interfaces.C.int
                             ) return access Skin_Callbacks;
   pragma Import (Stdcall, GetWindowLongPtrA, "GetWindowLongPtrA");
   
   function GET_X_LPARAM(l : LPARAM) return Integer is
   begin
      return Integer(l and 16#FFFF#);
   end GET_X_LPARAM;
   
   function GET_Y_LPARAM(l : LPARAM) return Integer is
   begin
      return Integer(Interfaces.Shift_Right(Interfaces.Unsigned_32(l and 16#FFFF0000#), 16));
   end GET_Y_LPARAM;
   
   function LOWORD(v : DWORD) return Integer is
   begin
      return Integer(v and 16#FFFF#);
   end LOWORD;
   
   function HIWORD(v : DWORD) return Integer is
   begin
      return Integer(Interfaces.Shift_Right(Interfaces.Unsigned_32(v and 16#FFFF0000#), 16));
   end HIWORD;
   
   function BeginPaint(
                       win : HWND;
                       lpPaint : out PAINTSTRUCT
                      ) return HDC;
   pragma Import (Stdcall, BeginPaint, "BeginPaint");
   
   function EndPaint(
                     win : HWND;
                     lpPaint : access constant PAINTSTRUCT
                    ) return BOOL;
   pragma Import (Stdcall, EndPaint, "EndPaint");
   
   function GetWindowRect(
                          win : HWND;
                          lpRect : out RECT
                         ) return BOOL;
   pragma Import (Stdcall, GetWindowRect, "GetWindowRect");
   
   function CreateCompatibleBitmap(
                                   dc : HDC;
                                   cx, cy : Interfaces.C.int
                                  ) return HBITMAP;
   pragma Import (Stdcall, CreateCompatibleBitmap, "CreateCompatibleBitmap");
   
   function SelectObject(
                         dc : HDC;
                         h : HGDIOBJ
                        ) return HGDIOBJ;
   pragma Import (Stdcall, SelectObject, "SelectObject");
   
   function BitBlt(
                   dc : HDC;
                   x, y, cx, cy : Interfaces.C.int;
                   hdcSrc : HDC;
                   x1, y1 : Interfaces.C.int;
                   rop : DWORD
                  ) return BOOL;
   pragma Import (Stdcall, BitBlt, "BitBlt");
   
   function callback(
                     handle : HWND;
                     uMsg : UINT;
                     w : WPARAM;
                     l : LPARAM
                    ) return LRESULT;
   pragma Convention (Stdcall, callback);
   
   function callback(
                     handle : HWND;
                     uMsg : UINT;
                     w : WPARAM;
                     l : LPARAM
                    ) return LRESULT is
      sc : access Skin_Callbacks;
      previous_cursor : HCURSOR;
   begin
      if False then
         Put_Line ("callback");
      end if;
      
      sc := GetWindowLongPtrA(handle, GWLP_USERDATA);
      if sc /= null then
         Put_Line("callback: " & System.Address_Image(sc.all'Address));
      else
         Put_Line("callback: null");
      end if;
      
      case uMsg is
         when WM_CLOSE =>
            PostQuitMessage(0);
            return 0;
         when WM_ERASEBKGND => -- prevent flickering
            return 1;
         when WM_SETCURSOR =>
            if current_cursor = null then
               Put_Line("WM_SETCURSOR: error: current cursor is null.");
            else
               Put_Line("WM_SETCURSOR" & System.Address_Image(current_cursor.all'Address));
            end if;
            if current_cursor /= null then
               previous_cursor := SetCursor(current_cursor);
            end if;
            return 1;
         when others =>
            null;
      end case;
      -- sometimes w is null
      if sc /= null then
         case uMsg is
            when WM_PAINT =>
               Put_Line("WM_PAINT");
               sc.draw.all;
            when WM_LBUTTONDOWN =>
               if False then
                  Put_Line("WM_LBUTTONDOWN");
               end if;
               if sc.mouse_down /= null then
                  sc.mouse_down(GET_X_LPARAM(l), GET_Y_LPARAM(l));
               end if;
            when WM_LBUTTONUP =>
               if False then
                  Put_Line("WM_LBUTTONUP");
               end if;
               if sc.mouse_up /= null then
                  sc.mouse_up(GET_X_LPARAM(l), GET_Y_LPARAM(l));
               end if;
            when WM_MOUSEMOVE =>
               if True then
                  Put_Line("WM_MOUSEMOVE" & " (" & Integer'Image(GET_X_LPARAM(l)) & "," & Integer'Image(GET_Y_LPARAM(l)) & ")");
               end if;
               if sc.mouse_move /= null then
                  sc.mouse_move(GET_X_LPARAM(l), GET_Y_LPARAM(l));
               end if;
            when WM_SIZE =>
               if sc.resize /= null then
                  sc.resize(LOWORD(DWORD(l)), HIWORD(DWORD(l)));
               end if;
            when WM_SETFOCUS =>
               if sc.focus /= null then
                  sc.focus(True);
               end if;
            when WM_KILLFOCUS =>
               if sc.focus /= null then
                  sc.focus(False);
               end if;
            when WM_RBUTTONUP =>
               null;
            when others =>
               Put_Line("Other message.");
               null;
         end case;
      end if;
      return DefWindowProcA(handle, uMsg, w, l);
   end callback;
   
   procedure error(last_error : DWORD) is
      --buffer : LPCSTR;
      --r1 : DWORD;
      --r2 : Interfaces.C.int;
      --flags : Interfaces.Unsigned_32;
      --len : Interfaces.C.size_t;
      msg_ptr : Interfaces.C.Strings.chars_ptr;
      --msg : access Interfaces.C.char_array;
   begin
      Put_Line("The error function contains an error.");
      return;
      
      --Put("Error: ");
      -- This function is messing with the stack.
      --flags := FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS;
      --r1 := FormatMessageA(
      --                     DWORD(flags),
      --                     LPVOID(Null_Address),
      --                     last_error,
      --                     0,
      --                     buffer,
      --                     0
      --                    );
      --if r1 = 0 then
      --   raise Program_Error;
      --end if;
      
      --if buffer = LPCSTR(Null_Address) then
      --   Put_Line ("null error message");
      --   raise Program_Error;
      --end if;
      
      --msg_ptr := LPCSTR_To_chars_ptr(buffer);
      --len := Interfaces.C.Strings.Strlen(msg_ptr);
      --msg := new Interfaces.C.char_array'(Interfaces.C.Strings.Value(msg_ptr, len));
      --Put_Line(Interfaces.C.To_Ada(msg.all, True));
      
      --flags := MB_ICONERROR or MB_OK;
      --r2 := MessageBoxA(
      --                  HWND(Null_Address),
      --                  buffer,
      --                  LPCSTR(Null_Address),
      --                  UINT(flags)
      --                 );
      --if r2 = 0 then
      --   raise Program_Error;
      --end if;
   end error;

   procedure W32_Init is
      class : WNDCLASSA;
      instance : HINSTANCE := HINSTANCE(GetModuleHandleA(LPCSTR(Null_Address)));
      c_class_name : Interfaces.C.char_array := Interfaces.C.To_C(class_name);
   begin
      class.style := 0;
      class.cbClsExtra := Interfaces.C.int(0);
      class.cbWndExtra := Interfaces.C.int(0);
      class.lpszMenuName := LPCSTR(Null_Address);
      
      class.hbrBackground := HBRUSH(System'To_Address(COLOR_BNTFACE + 1));
      class.lpszClassName := LPCSTR(c_class_name'Address);
      class.lpfnWndProc := WNDPROC(callback'Address);
      if class.lpfnWndProc = WNDPROC(Null_Address) then
         -- ???
         Put_Line ("RegisterClass fails silently if lpfnWndProc is null.");
         raise Program_Error;
      end if;
      class.instance := instance;
      if class.instance = HINSTANCE(Null_Address) then
         -- TODO: what GetModuleHandle returns on error?
         Put_Line ("null instance");
         raise Program_Error;
      end if;
      class.icon := LoadIconA(HINSTANCE(Null_Address), MAKEINTRESOURCE(System'To_Address(IDI_APPLICATION)));
      if class.icon = HICON(Null_Address) then
         -- error(GetLastError);
         Put_Line ("Error loading default window icon.");
      end if;
      class.cursor := LoadCursorA(HINSTANCE(Null_Address), MAKEINTRESOURCE(System'To_Address(IDC_ARROW)));
      if class.cursor = null then
         -- error(GetLastError);
         Put_Line ("Error loading default window cursor.");
      end if;
      
      if RegisterClassA(class'Address) = ATOM(Null_Address) then
         Put_Line ("error registering classic window class: ");
         error(GetLastError);
         raise Program_Error;
      end if;
      
      mem_dc := CreateCompatibleDC(HDC(System'To_Address(0)));
      if mem_dc = HDC(Null_Address) then
         Put_Line ("error creating memory drawing context: ");
         error(GetLastError);
         raise Program_Error;
      end if;
      bmp_dc := CreateCompatibleDC(HDC(System'To_Address(0)));
      if mem_dc = HDC(Null_Address) then
         Put_Line ("error creating bitmap drawing context: ");
         error(GetLastError);
         raise Program_Error;
      end if;
   end W32_Init;
   
   procedure W32_Quit is
      r : BOOL;
      c_class_name : Interfaces.C.char_array := Interfaces.C.To_C(class_name);
   begin
      r := DeleteDC(mem_dc);
      if r = 0 then
         raise Program_Error;
      end if;
      
      r := DeleteDC(bmp_dc);
      if r = 0 then
         raise Program_Error;
      end if;
      
      r := UnregisterClassA(LPCSTR(c_class_name'Address), HINSTANCE(Null_Address));
      if r = 0 then
         raise Program_Error;
      end if;
   end W32_Quit;
   
   function W32_Create_Window(x : Integer; y: Integer; w : Integer; h : Integer; title : String; callbacks : access Skin_Callbacks) return Window is
      c_class_name : Interfaces.C.char_array := Interfaces.C.To_C(class_name);
      c_title : Interfaces.C.char_array := Interfaces.C.To_C(title);
      c_x : Interfaces.C.int := Interfaces.C.int(x);
      c_y : Interfaces.C.int := Interfaces.C.int(y);
      c_w : Interfaces.C.int := Interfaces.C.int(w);
      c_h : Interfaces.C.int := Interfaces.C.int(h);
      r : HWND;
      dwStyle : DWORD;
      ret1 : LONG_PTR;
   begin
      dwStyle := WS_MINIMIZEBOX or WS_POPUP;
      if callbacks /= null then
         Put_Line("sc1: " & System.Address_Image(callbacks.all'Address));
      end if;
      r := CreateWindowExA(0, LPCSTR(c_class_name'Address), LPCSTR(c_title'Address), dwStyle, c_x, c_y, c_w, c_h, Window_To_HWND(main_window), HMENU(Null_Address), HINSTANCE(Null_Address), callbacks);
      if False then
         Put_Line("HWND: " & System.Address_Image(System.Address(r)));
      end if;
      if r = HWND(Null_Address) then
         error(GetLastError);
         raise Program_Error;
      end if;
      ret1 := SetWindowLongPtrA(r, GWLP_USERDATA, callbacks);
      return HWND_To_Window(r);
   end W32_Create_Window;
   
   procedure W32_Destroy_Window(w : Window) is
      r : BOOL;
   begin
      r := DestroyWindow(Window_To_HWND(w));
      if r = 0 then
         raise Program_Error;
      end if;
   end W32_Destroy_Window;
   
   procedure W32_Event_Handler is
      message : MSG;
      r1 : BOOL;
      r2 : LRESULT;
   begin
      loop
         r1 := GetMessageA(LPMSG(message'Address), HWND(Null_Address), 0, 0);
         exit when r1 = 0;
         r1 := TranslateMessage(LPMSG(message'Address));
         r2 := DispatchMessageA(LPMSG(message'Address));
      end loop;
   end W32_Event_Handler;
   
   procedure W32_Show_Window(w : Window) is
      r : BOOL;
   begin
      if False then
         Put_Line("ShowWindow HWND: " & System.Address_Image(System.Address(Window_To_HWND(w))));
      end if;
      r := ShowWindow(Window_To_HWND(w), SW_SHOW);
      if r = 0 then
         --error(GetLastError);
         null;
      end if;
   end W32_Show_Window;
   
   procedure W32_Hide_Window(w : Window) is
      r : BOOL;
   begin
      r := ShowWindow(Window_To_HWND(w), SW_HIDE);
      if r = 0 then
         null;
      end if;
   end W32_Hide_Window;
   
   procedure W32_Move_Window(w : Window; x : Integer; y : Integer) is
   begin
      null;
   end W32_Move_Window;
   
   procedure W32_Redraw_Window(w : Window) is
      r : BOOL;
   begin
      r := RedrawWindow (w, Null_Address, Null_Address, RDW_INVALIDATE);
   end W32_Redraw_Window;
   
   procedure W32_Set_Topmost(w : Window) is
   begin
      null;
   end W32_Set_Topmost;
   
   procedure W32_Set_Not_Topmost(w : Window) is
   begin
      null;
   end W32_Set_Not_Topmost;
   
   procedure W32_Resize_Window(w : Window; width : Integer; height : Integer) is
   begin
      null;
   end W32_Resize_Window;
   
   procedure W32_Get_Window_Rect(rect : Color) is
   begin
      null;
   end W32_Get_Window_Rect;
   
   procedure W32_Minimize_Window(w : Window) is
   begin
      null;
   end W32_Minimize_Window;
   
   function W32_Load_Image(filename : String) return Pixmap is
      bitmap : HANDLE;
      c_filename : Interfaces.C.char_array := Interfaces.C.To_C(filename);
   begin
      bitmap := LoadImageA(HINSTANCE(Null_Address), LPCSTR(c_filename'Address), IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE);
      return HANDLE_To_Pixmap(bitmap);
   end W32_Load_Image;
   
   procedure W32_Unload_Image(image : Pixmap) is
   begin
      null;
   end W32_Unload_Image;
   
   procedure W32_Begin_Drawing(w : Window) is
      r : RECT;
      width, height : Interfaces.C.int;
      ret1 : HDC;
      ret2 : HGDIOBJ;
      ret3 : BOOL;
   begin
      ret1 := BeginPaint(Window_To_HWND(w), p);
      cur_window := Window_To_HWND(w);
      
      ret3 := GetWindowRect(Window_To_HWND(w), r);
      width := Interfaces.C.int(r.right - r.left);
      height := Interfaces.C.int(r.bottom - r.top);
      mem_bmp := CreateCompatibleBitmap(p.dc, width, height);
      ret2 := SelectObject(mem_dc, HGDIOBJ(mem_bmp));
   end W32_Begin_Drawing;
   
   procedure W32_Draw_Image(p : Pixmap; dst_x : Integer; dst_y : Integer; w : Integer; h : Integer; src_x : Integer; src_y : Integer)
   is
      ret1 : BOOL;
      ret2 : HGDIOBJ;
   begin
      ret2 := SelectObject(bmp_dc, HGDIOBJ(p));
      ret1 := BitBlt(
                     mem_dc,
                     Interfaces.C.int(dst_x),
                     Interfaces.C.int(dst_y),
                     Interfaces.C.int(w),
                     Interfaces.C.int(h),
                     bmp_dc,
                     Interfaces.C.int(src_x),
                     Interfaces.C.int(src_y),
                     SRCCOPY
                    );
      Put_Line("dst_x=" & dst_x'Image & " dst_y=" & dst_y'Image & " w=" & w'Image & " h=" & h'Image & " src_x=" & src_x'Image & " src_y=" & src_y'Image);
   end W32_Draw_Image;
   
   procedure W32_Draw_Image_Double(p : Pixmap; dst_x : Integer; dst_y : Integer; w : Integer; h : Integer; src_x : Integer; src_y : Integer) is
   begin
      null;
   end W32_Draw_Image_Double;
   
   procedure W32_Draw_Filled_Rectangle(x : Integer; y : Integer; w : Integer; h : Integer; c : Color) is
   begin
      null;
   end W32_Draw_Filled_Rectangle;
   
   procedure W32_End_Drawing
   is
      r : RECT;
      width, height : Interfaces.C.int;
      ret1 : BOOL;
   begin
      ret1 := GetWindowRect(cur_window, r);
      width := Interfaces.C.int(r.right - r.left);
      height := Interfaces.C.int(r.bottom - r.top);
      ret1 := BitBlt(p.dc, 0, 0, width, height, mem_dc, 0, 0, SRCCOPY);
      ret1 := EndPaint(cur_window, new PAINTSTRUCT'(p));
   end W32_End_Drawing;
   
   procedure W32_Capture_Mouse(w : Window) is
   begin
      null;
   end W32_Capture_Mouse;
   
   procedure W32_Release_Mouse is
   begin
      null;
   end W32_Release_Mouse;
   
   function W32_Load_Cursor(filename : String) return Cursor is
      c_filename : Interfaces.C.char_array := Interfaces.C.To_C(filename);
      cursor : HANDLE;
   begin
      cursor := LoadImageA(HINSTANCE(Null_Address), LPCSTR(c_filename'Address), IMAGE_CURSOR, 0, 0, LR_LOADFROMFILE);
      return HANDLE_To_Cursor(cursor);
   end W32_Load_Cursor;
   
   procedure W32_Unload_Cursor(p : Cursor) is
   begin
      null;
   end W32_Unload_Cursor;
   
   procedure W32_Set_Cursor(p : Cursor) is
   begin
      current_cursor := HCURSOR(p);
   end W32_Set_Cursor;

   function W32_Check_Glue(a : Window; b : Window; x : Integer; y : Integer) return Boolean is
   begin
      return False;
   end W32_Check_Glue;

   procedure W32_Open_File_Dialog is
   begin
      null;
   end W32_Open_File_Dialog;
   
   procedure W32_Open_Dir_Dialog is
   begin
      null;
   end W32_Open_Dir_Dialog;

end w32;
