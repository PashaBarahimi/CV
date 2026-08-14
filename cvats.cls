%% cvats.cls -- ATS-safe variant of the CV class.
%%
%% Same macro API as cvstyle.cls, so sections/*.tex are shared verbatim. Only
%% the rendering differs. Everything here is chosen so an applicant-tracking
%% system can extract the text in reading order:
%%
%%   - single column, no tabular positioning anywhere. Text in table cells is a
%%     common cause of scrambled extraction order.
%%   - no icon glyphs. Contact lines spell out "Email:", "GitHub:" etc.
%%   - black only, no accent colour.
%%   - no letterspacing. \textls inserts kerns between letters, which can split
%%     a word into separate runs on extraction.
%%   - no running header or footer. Parsers routinely discard them.
%%   - one contact per line, and no middots or pipes as separators.
%%
%% ---------------------------------------------------------------------------

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{cvats}[2026/08/13 v1.0 ATS-safe CV class]

\newif\ifcv@letter \cv@letterfalse
\DeclareOption{a4paper}{\cv@letterfalse}
\DeclareOption{letterpaper}{\cv@lettertrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax

\LoadClass[11pt]{article}

\RequirePackage{fix-cm}
\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}
\RequirePackage{XCharter}
\RequirePackage{etoolbox}
\RequirePackage{enumitem}
\RequirePackage[hidelinks]{hyperref}

\ifcv@letter
  \RequirePackage[letterpaper,margin=2cm]{geometry}
\else
  \RequirePackage[a4paper,margin=2cm]{geometry}
\fi

\pagestyle{plain}
\setlength{\parindent}{0pt}
\setlength{\parskip}{0pt}
\linespread{1.05}
\raggedright

\hypersetup{pdfcreator={pdfLaTeX}}

% ---------------------------------------------------------------------------
% Spacing -- same three constants, so the rhythm is recognisably the same
% ---------------------------------------------------------------------------
\newlength{\cvSectionSkip}\setlength{\cvSectionSkip}{12pt}
\newlength{\cvRuleSkip}   \setlength{\cvRuleSkip}{4pt}
\newlength{\cvEntrySkip}  \setlength{\cvEntrySkip}{8pt}

% ---------------------------------------------------------------------------
% Title block
% ---------------------------------------------------------------------------
\newcommand{\cv@name}{}
\newcommand{\cvname}[1]{%
  \gdef\cv@name{#1}%
  \hypersetup{pdfauthor={#1},pdftitle={#1 -- Curriculum Vitae},%
              pdfsubject={Curriculum Vitae}}%
  {\LARGE\bfseries #1\par}%
  \vspace{\cvRuleSkip}%
}

\newcommand{\cvtagline}[1]{#1\par\vspace{\cvRuleSkip}}

% One contact per line, each labelled. No icons, no separators to misparse.
\newcommand{\cv@contact}[2]{#1: #2\par}
\newenvironment{cvcontacts}{\par}{\par}
\newcommand{\cvcontactbreak}{}

\newcommand{\cvemail}[1]{\cv@contact{Email}{#1}}
\newcommand{\cvwebsite}[1]{\cv@contact{Website}{#1}}
\newcommand{\cvgithub}[1]{\cv@contact{GitHub}{github.com/#1}}
\newcommand{\cvlinkedin}[1]{\cv@contact{LinkedIn}{linkedin.com/in/#1}}
\newcommand{\cvscholar}[1]{\cv@contact{Google Scholar}{scholar.google.com/citations?user=#1}}
\newcommand{\cvorcid}[1]{\cv@contact{ORCID}{#1}}
\newcommand{\cvlocation}[1]{\cv@contact{Location}{#1}}

% ---------------------------------------------------------------------------
% Sections and entries -- all linear paragraphs, no tabulars
% ---------------------------------------------------------------------------
\newcommand{\cvsection}[1]{%
  \par\vspace{\cvSectionSkip}%
  {\large\bfseries #1}\par
  \vspace{2pt}\hrule\vspace{\cvRuleSkip}%
}

% Dates go on their own line rather than a right-aligned column: a right-aligned
% date in a tabular is the single most common way an entry's dates get attached
% to the wrong entry on extraction.
\newcommand{\cvevent}[4]{%
  \par\vspace{\cvEntrySkip}%
  \textbf{#1}\ifblank{#2}{}{, #2}\par
  \ifblank{#3}{}{#3\par}%
  \ifblank{#4}{}{#4\par}%
}

\newcommand{\cvadvisor}[2][]{Advisor: #2\ifblank{#1}{}{, #1}\par}
\newcommand{\cvsummary}[1]{#1\par}

\newcommand{\cvpublication}[5][]{%
  \par\vspace{\cvEntrySkip}%
  \textbf{#2}\par
  \ifblank{#3}{}{#3\par}%
  \ifblank{#4}{}{#4, #5\ifblank{#1}{}{ (#1)}\par}%
}

\newcommand{\cvproject}[3]{%
  \par\vspace{\cvEntrySkip}%
  \textbf{#1}\ifblank{#2}{}{, #2}\par
  \ifblank{#3}{}{#3\par}%
}

% The three list environments are plain itemize/paragraph runs. Bulleted lists
% extract reliably; aligned columns do not.
\newenvironment{cvhonorlist}{\par\vspace{\cvEntrySkip}\cv@list}{\endcv@list}
\newcommand{\cvhonor}[3]{\item #2\ifblank{#3}{}{, #3} (#1)}

\newenvironment{cvteachinglist}{\par\vspace{\cvEntrySkip}\cv@list}{\endcv@list}
\newcommand{\cvteaching}[3]{\item #1, #2 (#3)}

% Skills stay label-per-line rather than bulleted: "Programming: C++, Python..."
% is the shape keyword extractors expect.
\newenvironment{cvskilllist}{\par\vspace{\cvEntrySkip}}{\par}
\newcommand{\cvskill}[2]{\textbf{#1:} #2\par}

\newenvironment{cv@list}
  {\begin{itemize}[leftmargin=1.4em,topsep=2pt,partopsep=0pt,parsep=0pt,%
                   itemsep=2pt,label=\textbullet]}
  {\end{itemize}}

\newenvironment{cvitems}{\cv@list}{\endcv@list}
\newcommand{\cvitem}[1]{\item #1}

\newcommand{\cvprose}[1]{\par\vspace{\cvEntrySkip}#1\par}

\newcommand{\cvlastupdated}{%
  \par\vspace{\cvSectionSkip}Last updated: \cv@monthname~\the\year\par}
\newcommand{\cv@monthname}{%
  \ifcase\month\or Jan\or Feb\or Mar\or Apr\or May\or Jun\or
  Jul\or Aug\or Sep\or Oct\or Nov\or Dec\fi}

% ---------------------------------------------------------------------------
% Inline helpers
% ---------------------------------------------------------------------------
% Links are dropped to plain text. The URLs that matter to a reader are in the
% contact block, spelled out; body links add nothing an ATS can use.
\newcommand{\cvinst}[2]{\textbf{#2}}
\newcommand{\cvlink}[2]{#2}
\newcommand{\cvme}{\textbf{P.~Barahimi}}

% Plain text rather than a raised superscript: superscripts can extract out of
% order or with stray spacing.
\newcommand{\cvordinal}[2]{#1#2}
\newcommand{\cvapprox}{\textasciitilde}
\newcommand{\Csharp}{C\#}
\newcommand{\Cpp}{C++}
\newcommand{\cvtodo}[1]{[TODO: #1]}

\endinput
