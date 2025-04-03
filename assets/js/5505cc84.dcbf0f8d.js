"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[318],{48734:(e,n,r)=>{r.r(n),r.d(n,{assets:()=>s,contentTitle:()=>l,default:()=>c,frontMatter:()=>i,metadata:()=>d,toc:()=>o});const d=JSON.parse('{"id":"Global","title":"_G","description":"By default, GAdminV2 adds a custom key to G to make it easier for addons to access GAdmin without requiring additional imports.","source":"@site/docs/Global.md","sourceDirName":".","slug":"/Global","permalink":"/GAdminV2/docs/Global","draft":false,"unlisted":false,"editUrl":"https://github.com/gdr1461/GAdminV2/edit/main/docs/Global.md","tags":[],"version":"current","sidebarPosition":9,"frontMatter":{"sidebar_position":9},"sidebar":"defaultSidebar","previous":{"title":"Command Arguments","permalink":"/GAdminV2/docs/Arguments"}}');var a=r(74848),t=r(28453);const i={sidebar_position:9},l="_G",s={},o=[{value:"Server",id:"server",level:2},{value:"API",id:"api",level:3},{value:"Modified",id:"modified",level:3},{value:"Module",id:"module",level:3},{value:"Path",id:"path",level:3},{value:"Render",id:"render",level:3},{value:"Scheduler",id:"scheduler",level:3},{value:"__GetBanData",id:"__getbandata",level:3},{value:"Client",id:"client",level:2},{value:"Path",id:"path-1",level:3},{value:"Render",id:"render-1",level:3},{value:"__GetBanData",id:"__getbandata-1",level:3},{value:"Framework",id:"framework",level:3},{value:"Scheduler",id:"scheduler-1",level:3},{value:"UseTheme",id:"usetheme",level:3},{value:"Theme",id:"theme",level:3}];function h(e){const n={a:"a",admonition:"admonition",code:"code",h1:"h1",h2:"h2",h3:"h3",header:"header",p:"p",pre:"pre",...(0,t.R)(),...e.components};return(0,a.jsxs)(a.Fragment,{children:[(0,a.jsx)(n.header,{children:(0,a.jsx)(n.h1,{id:"_g",children:"_G"})}),"\n",(0,a.jsxs)(n.p,{children:["By default, GAdminV2 adds a custom key to ",(0,a.jsx)(n.a,{href:"https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#_G",children:"_G"})," to make it easier for addons to access GAdmin without requiring additional imports.\r\nYou can access GAdmin by typing ",(0,a.jsx)(n.code,{children:"_G.GAdmin"})," on either the server or client side."]}),"\n",(0,a.jsx)(n.admonition,{type:"note",children:(0,a.jsxs)(n.p,{children:[(0,a.jsx)(n.code,{children:"_G.GAdmin"})," has different properties depending on whether it is accessed from the server or client side."]})}),"\n",(0,a.jsx)(n.h2,{id:"server",children:"Server"}),"\n",(0,a.jsx)(n.p,{children:"Global properties of GAdmin on the server side:"}),"\n",(0,a.jsx)(n.pre,{children:(0,a.jsx)(n.code,{className:"language-lua",children:"{\r\n\tAPI = ServerAPI,\r\n\tModified = true,\r\n\tModule = MainModule,\r\n\tPath = MainModuleScript,\r\n\tRender: Render,\r\n\tScheduler: Scheduler,\r\n\t__GetBanData: (RawBanData: table) -> BanData\r\n}\n"})}),"\n",(0,a.jsx)(n.h3,{id:"api",children:"API"}),"\n",(0,a.jsxs)(n.p,{children:["GAdmin's ",(0,a.jsx)(n.a,{href:"/api/ServerAPI",children:"Server API"}),"."]}),"\n",(0,a.jsx)(n.h3,{id:"modified",children:"Modified"}),"\n",(0,a.jsx)(n.p,{children:"A boolean indicating whether GAdmin has been modified by addons."}),"\n",(0,a.jsx)(n.h3,{id:"module",children:"Module"}),"\n",(0,a.jsxs)(n.p,{children:["The required ",(0,a.jsx)(n.a,{href:"/api/MainModule",children:"module"})," from the path ",(0,a.jsx)(n.code,{children:"GAdminV2.MainModule"}),"."]}),"\n",(0,a.jsx)(n.h3,{id:"path",children:"Path"}),"\n",(0,a.jsxs)(n.p,{children:["A shortcut to the ",(0,a.jsx)(n.code,{children:"MainModule"})," path for easier access to the Server folder (e.g., ",(0,a.jsx)(n.code,{children:"GAdminV2.MainModule"}),")."]}),"\n",(0,a.jsx)(n.h3,{id:"render",children:"Render"}),"\n",(0,a.jsxs)(n.p,{children:["GAdmin's ",(0,a.jsx)(n.a,{href:"/api/Render",children:"Renderer"})]}),"\n",(0,a.jsx)(n.h3,{id:"scheduler",children:"Scheduler"}),"\n",(0,a.jsxs)(n.p,{children:["GAdmin's ",(0,a.jsx)(n.a,{href:"/api/Scheduler",children:"Scheduler"})]}),"\n",(0,a.jsx)(n.h3,{id:"__getbandata",children:"__GetBanData"}),"\n",(0,a.jsx)(n.p,{children:"Used locally in the system to retrieve dictionary-based ban data from an array."}),"\n",(0,a.jsx)(n.pre,{children:(0,a.jsx)(n.code,{className:"language-lua",children:'local BanData = _G.GAdmin.__GetBanData({\r\n\t00000, -- Moderator ID\r\n\t"No reason.", -- Reason\r\n\t"00000000", -- The time in Unix timestamp format, converted to a string.\r\n\t"00000000", -- The Unix timestamp of when a user was banned.\r\n\tnil, -- Indicates whether a user has been banned locally (deprecated property).\r\n\ttrue, -- ApplyToUniverse \u2013 used for the Roblox Ban API.\r\n\tnil, -- The type of ban (Global/Server) (deprecated property)..\r\n\t"No reason." -- ModHint.\r\n})\n'})}),"\n",(0,a.jsx)(n.h2,{id:"client",children:"Client"}),"\n",(0,a.jsx)(n.h3,{id:"path-1",children:"Path"}),"\n",(0,a.jsxs)(n.p,{children:["A shortcut to the ",(0,a.jsx)(n.code,{children:"GAdminShared"})," path for easier access to the main folder (e.g., ",(0,a.jsx)(n.code,{children:"ReplicatedStorage.GAdminShared"}),")."]}),"\n",(0,a.jsx)(n.h3,{id:"render-1",children:"Render"}),"\n",(0,a.jsxs)(n.p,{children:["GAdmin's ",(0,a.jsx)(n.a,{href:"/api/Render",children:"Renderer"})]}),"\n",(0,a.jsx)(n.h3,{id:"__getbandata-1",children:"__GetBanData"}),"\n",(0,a.jsx)(n.p,{children:"Used locally in the system to retrieve dictionary-based ban data from an array."}),"\n",(0,a.jsx)(n.pre,{children:(0,a.jsx)(n.code,{className:"language-lua",children:'local BanData = _G.GAdmin.__GetBanData({\r\n\t00000, -- Moderator ID\r\n\t"No reason.", -- Reason\r\n\t"00000000", -- The time in Unix timestamp format, converted to a string.\r\n\t"00000000", -- The Unix timestamp of when a user was banned.\r\n\tnil, -- Indicates whether a user has been banned locally (deprecated property).\r\n\ttrue, -- ApplyToUniverse \u2013 used for the Roblox Ban API.\r\n\tnil, -- The type of ban (Global/Server) (deprecated property)..\r\n\t"No reason." -- ModHint.\r\n})\n'})}),"\n",(0,a.jsx)(n.h3,{id:"framework",children:"Framework"}),"\n",(0,a.jsxs)(n.p,{children:["GAdmin's ",(0,a.jsx)(n.a,{href:"/api/Framework",children:"Framework"})]}),"\n",(0,a.jsx)(n.h3,{id:"scheduler-1",children:"Scheduler"}),"\n",(0,a.jsxs)(n.p,{children:["GAdmin's ",(0,a.jsx)(n.a,{href:"/api/Scheduler",children:"Scheduler"})]}),"\n",(0,a.jsx)(n.h3,{id:"usetheme",children:"UseTheme"}),"\n",(0,a.jsx)(n.p,{children:"Boolean that tells the system whether the theme should be applied to the UI panel when the Theme setting is changed."}),"\n",(0,a.jsx)(n.h3,{id:"theme",children:"Theme"}),"\n",(0,a.jsx)(n.p,{children:(0,a.jsx)(n.a,{href:"/api/UI#Theme",children:"Theme Data"})})]})}function c(e={}){const{wrapper:n}={...(0,t.R)(),...e.components};return n?(0,a.jsx)(n,{...e,children:(0,a.jsx)(h,{...e})}):h(e)}},28453:(e,n,r)=>{r.d(n,{R:()=>i,x:()=>l});var d=r(96540);const a={},t=d.createContext(a);function i(e){const n=d.useContext(t);return d.useMemo((function(){return"function"==typeof e?e(n):{...n,...e}}),[n,e])}function l(e){let n;return n=e.disableParentContext?"function"==typeof e.components?e.components(a):e.components||a:i(e.components),d.createElement(t.Provider,{value:n},e.children)}}}]);