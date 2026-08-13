%% cvstyle.cls -- document class for a two-page academic CV.
%%
%% ALL design decisions live in this file. Content files under sections/
%% must contain no formatting code -- only the semantic macros defined here.
%%
%% Engine: pdfLaTeX (see CV-SPEC.md sec. 1). Do not switch to XeLaTeX/LuaLaTeX.
%%
%% Class options:
%%   a4paper     (default) A4 page geometry
%%   letterpaper US Letter page geometry
%%
%% ---------------------------------------------------------------------------

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{cvstyle}[2026/08/10 v1.0 Academic CV class]

% ---------------------------------------------------------------------------
% Class options
% ---------------------------------------------------------------------------
% Declaration order matters: \ProcessOptions executes declared options in the
% order they appear below, so letterpaper wins if both are somehow requested.
\newif\ifcv@letter \cv@letterfalse
\DeclareOption{a4paper}{\cv@letterfalse}
\DeclareOption{letterpaper}{\cv@lettertrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax

\LoadClass[11pt]{article}

% ---------------------------------------------------------------------------
% Packages
% ---------------------------------------------------------------------------
% fix-cm must come before any font package. Computer Modern ships only in
% discrete sizes, and the 10.5pt body size below is not one of them; without
% this, the residual CM families (notably the math fonts, which XCharter does
% not replace) emit "Font shape ... in size <10.5> not available" warnings and
% get silently substituted at 10.95.
\RequirePackage{fix-cm}
\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc}
\RequirePackage{XCharter}          % body + heading font (real small caps)
% Body size. article offers no 10.5pt option, so the class is loaded at 11pt
% and stepped down here. Spec sec. 3 permits 10.5 or 11; do not go below 10.
\RequirePackage[fontsize=10.5pt]{fontsize}
\RequirePackage{microtype}         % protrusion + expansion (spec 2.6)
\RequirePackage{xcolor}
\RequirePackage{etoolbox}
\RequirePackage{tabularx}
\RequirePackage{array}
\RequirePackage{enumitem}
\RequirePackage{needspace}         % page-break control (spec 2.1)
\RequirePackage{fancyhdr}          % running header (spec 2.2)
\RequirePackage{lastpage}
\RequirePackage{fontawesome5}      % contact icons
\RequirePackage{xurl}
\RequirePackage[hidelinks]{hyperref}

% ---------------------------------------------------------------------------
% Page geometry (spec sec. 3)
% ---------------------------------------------------------------------------
% headheight/headsep sit inside the top margin; 1.8cm = ~51pt leaves ~27pt of
% paper above the running header, which is comfortable.
%
% US Letter is ~50pt SHORTER than A4 (792pt vs 842pt) while being 17pt wider.
% At A4's margins the content runs to three pages, so the Letter variant sits
% at 1.5cm -- the floor spec sec. 3 permits -- to win that height back both
% vertically and (via a wider measure, hence fewer wrapped lines) horizontally.
% This is the primary reason A4 is the default: it holds two pages with room
% to spare, Letter only just does.
\ifcv@letter
  \RequirePackage[letterpaper,left=1.5cm,right=1.5cm,top=1.5cm,bottom=1.5cm,%
                  headheight=14pt,headsep=10pt]{geometry}
\else
  \RequirePackage[a4paper,left=1.8cm,right=1.8cm,top=1.8cm,bottom=1.8cm,%
                  headheight=14pt,headsep=10pt]{geometry}
\fi

\linespread{1.05}
\setlength{\parindent}{0pt}
\setlength{\parskip}{0pt}
\setlength{\tabcolsep}{0pt}
% \raggedbottom, not \flushbottom: vertical justification was tried to even out
% the pages and made things worse -- it changed the page builder's break
% decisions and pushed the document to three, with both earlier pages still
% short. Pages end where the content ends.
\raggedbottom

% Ragged right, not justified. A CV is read in fragments, so a flush right edge
% buys nothing and costs even word spacing: justification was stretching the
% skills rows and the longer bullets visibly. ragged2e rather than plain
% \raggedright because it keeps sane spacing inside p/X table columns too.
\RequirePackage{ragged2e}
% Infinite right-skip stretch rather than ragged2e's default 0pt plus 2em.
% With limited stretch, a line ending well short of the margin is penalised, so
% TeX prefers to overflow rather than push an unbreakable token to the next
% line -- an \mbox or a long closed-up compound then sticks past the margin.
% Infinite stretch makes ending short free, so unbreakable content always moves
% down instead. Costs a slightly more ragged edge; buys immunity to overfull.
\setlength{\RaggedRightRightskip}{0pt plus 1fil}
\RaggedRight
% No automatic hyphenation: "cryptogra-phy" and "reduc-tion" broken across
% lines read as cheapness on a CV, and ragged right removes the need for them.
\hyphenpenalty=10000
% Breaks at hyphens that are really in the word stay legal but discouraged.
% Forbidding these outright costs an overfull line, since a long hyphenated
% compound then has to fit whole or not at all.
\exhyphenpenalty=100

% Never break a paragraph so that a single line is stranded (spec 2.1).
\widowpenalty=10000
\clubpenalty=10000
\displaywidowpenalty=10000
\brokenpenalty=10000

% ---------------------------------------------------------------------------
% Colour (spec 2.5)
% ---------------------------------------------------------------------------
% Exactly one accent colour. It is reserved for hyperlinks: if it is
% accent-coloured, it is clickable. Deep navy -- desaturated enough to remain
% legible when the PDF is printed in greyscale.
\definecolor{accent}{HTML}{1F3864}
% Links sit a step below the accent: a desaturated slate, clearly clickable and
% clearly not black, but no longer competing with section headings. Before this
% split, headings and every institution, advisor and venue shared one colour,
% so the accent meant both "this is structure" and "this is a link" -- and the
% loudest things on the page were employers rather than accomplishments.
% Still dark enough to hold up in greyscale print.
\definecolor{cvlink}{HTML}{4F6180}
% Muted grey is NOT an accent; spec 2.2 mandates it for the running header only.
\definecolor{cvmuted}{HTML}{6E6E6E}

\hypersetup{
  colorlinks = true,
  allcolors  = cvlink,
  breaklinks = true,
  pdfcreator = {pdfLaTeX},
}

% ---------------------------------------------------------------------------
% Vertical rhythm (spec sec. 3)
% ---------------------------------------------------------------------------
% EXACTLY three spacing constants exist. Nothing else in this class or in any
% content file may introduce ad-hoc \vspace. Space above a section heading
% must exceed the space below its rule, so headings group downward.
\newlength{\cvSectionSkip}\setlength{\cvSectionSkip}{10pt} % above a section heading
\newlength{\cvRuleSkip}   \setlength{\cvRuleSkip}{4pt}     % below a section rule
\newlength{\cvEntrySkip}  \setlength{\cvEntrySkip}{5pt}    % between entries

% ---------------------------------------------------------------------------
% Running header (spec 2.2)
% ---------------------------------------------------------------------------
\newcommand{\cv@name}{}

\fancypagestyle{cvpage}{%
  \fancyhf{}%
  \renewcommand{\headrulewidth}{0.4pt}%
  \renewcommand{\headrule}{{\color{cvmuted}%
    \hrule width\headwidth height\headrulewidth}}%
  \fancyhead[L]{\footnotesize\color{cvmuted}\cv@name}%
  % \pageref* (starred) suppresses the hyperlink: an accent-coloured digit in
  % the header would violate "accent means clickable" (spec 2.5) by looking
  % like a link where none is wanted.
  \fancyhead[R]{\footnotesize\color{cvmuted}Page~\thepage\ of~\pageref*{LastPage}}%
}

% Page 1 carries no header: the name is already in the title block.
\fancypagestyle{cvfirstpage}{%
  \fancyhf{}%
  \renewcommand{\headrulewidth}{0pt}%
}

\pagestyle{cvpage}
\AtBeginDocument{\thispagestyle{cvfirstpage}}

% ---------------------------------------------------------------------------
% Title block
% ---------------------------------------------------------------------------
% {\centering ...\par} rather than the center environment: center adds its own
% \topsep, which would be a fourth source of vertical space.
\newcommand{\cvname}[1]{%
  \gdef\cv@name{#1}%
  \hypersetup{pdfauthor={#1},pdftitle={#1 -- Curriculum Vitae},%
              pdfsubject={Academic Curriculum Vitae}}%
  % Letterspaced: the name is the one place the page can carry any identity,
  % and unmodified bold XCharter reads as just another heading. microtype's
  % \textls tracks it open enough to act as an anchor without looking styled.
  {\centering\huge\bfseries\textls[60]{#1}\par}%
  \vspace{\cvRuleSkip}%
}

% Constrained width so a long tagline breaks into balanced lines rather than
% stranding one word.
% One size down and in the muted grey. At full body size and black the tagline
% weighed the same as the text below it, so the header read as three roughly
% equal bands instead of descending from the name.
\newcommand{\cvtagline}[1]{%
  {\centering\small\color{cvmuted}%
   \begin{minipage}{0.86\linewidth}\centering #1\end{minipage}\par}%
  \vspace{\cvRuleSkip}%
}

% Contact line. Content supplies semantic entries (\cvemail{...} etc.); the
% icon, the URL scheme and the separators are chosen here, not in content.
\newif\ifcv@firstcontact
\newcommand{\cv@contact}[3]{%
  \ifcv@firstcontact\cv@firstcontactfalse\else\hspace{0.9em}\fi
  \ifblank{#2}{\mbox{#1\,#3}}{\href{#2}{\mbox{#1\,#3}}}%
}
\newenvironment{cvcontacts}
  {\par\cv@firstcontacttrue\centering\footnotesize}
  {\par}

% Start a new centred row of contacts. Resetting the flag suppresses the
% leading separator that would otherwise open the new row. Use this to balance
% the rows deliberately rather than letting the line break where it lands --
% natural wrapping strands the last item on a row of its own.
\newcommand{\cvcontactbreak}{\par\cv@firstcontacttrue}

\newcommand{\cvgithub}[1]{\cv@contact{\faGithub}{https://github.com/#1}{#1}}
\newcommand{\cvlinkedin}[1]{\cv@contact{\faLinkedin}{https://linkedin.com/in/#1}{#1}}
\newcommand{\cvwebsite}[1]{\cv@contact{\faGlobe}{https://#1}{#1}}
\newcommand{\cvemail}[1]{\cv@contact{\faEnvelope}{mailto:#1}{#1}}
\newcommand{\cvlocation}[1]{\cv@contact{\faMapMarker*}{}{#1}}
% Academic profile links. Argument is the bare ID, not a URL -- the scheme is
% built here so it cannot be mistyped per-use.
\newcommand{\cvscholar}[1]{%
  \cv@contact{\faGraduationCap}{https://scholar.google.com/citations?user=#1}{Google Scholar}}
% Labelled "ORCID" rather than printing the bare 19-character iD, which would
% push the contact line onto a third row. Swap {ORCID} for {#1} to show the
% full identifier instead.
\newcommand{\cvorcid}[1]{\cv@contact{\faOrcid}{https://orcid.org/#1}{ORCID}}

% ---------------------------------------------------------------------------
% Sections (spec sec. 3, 4)
% ---------------------------------------------------------------------------
% \cv@firstentry suppresses \cvEntrySkip on the first entry after a rule, so
% the gap under a heading is always exactly \cvRuleSkip.
\newif\ifcv@firstentry \cv@firstentryfalse

\newcommand{\cvsection}[1]{%
  \par
  % Reserve the heading apparatus (~2 baselines) PLUS \cv@entryneed for the
  % entry that follows, so a heading can never be stranded at the foot of a
  % page (spec 2.1). The first entry deliberately does not re-check this --
  % see \cv@entrystart.
  \needspace{8\baselineskip}%
  \vspace{\cvSectionSkip}%
  % Accent, not black: previously the only coloured things on the page were
  % hyperlinked institution and advisor names, so the eye landed on employers
  % rather than on structure. Section headings now out-rank inline links.
  {\large\bfseries\scshape\color{accent} #1}%
  \par\nobreak
  \vspace{3pt}%
  {\color{accent}\hrule height 0.8pt}%
  \par\nobreak
  \vspace{\cvRuleSkip}%
  \nopagebreak
  \@afterheading
  \cv@firstentrytrue
}

% Starts an entry: emits the inter-entry gap and reserves #1 of vertical space.
%
% Both are skipped for the FIRST entry in a section. \needspace works by
% offering a legal breakpoint, so calling it immediately after a section rule
% hands TeX permission to break exactly where a heading would be stranded --
% which is the defect spec 2.1 is about. \cvsection has already reserved room
% for the heading plus this entry, so re-checking here is both redundant and
% harmful.
% How much room an entry heading needs below it. Derived, not guessed: the
% bottom 15% band that spec 2.1 forbids headings from entering begins about
% 75pt above the foot of the text block on both A4 and US Letter, and 6
% baselines at 10.5pt/1.05 is ~79pt. Reserving less lets a heading land inside
% the band; reserving much more wastes page space under \raggedbottom.
% Derived, not guessed: the bottom 15% band that a heading must not enter
% begins about 75pt above the foot of the text block on both paper sizes, and
% 6 baselines at 10.5pt/1.05 is ~79pt.
%
% Note this is NOT what causes a gap at the foot of a page. \nobreak between an
% entry's heading, advisor line and bullets, plus the 10000 widow/club
% penalties, make an entry atomic: an entry taller than the space remaining
% moves whole, whatever this value is. Such a gap can only be closed by letting
% entries split across pages.
\newcommand{\cv@entryneed}{6\baselineskip}

\newcommand{\cv@entrystart}[1]{%
  \par
  \ifcv@firstentry
    \cv@firstentryfalse
  \else
    \vspace{\cvEntrySkip}%
    \needspace{#1}%
  \fi
}

% ---------------------------------------------------------------------------
% Entry macros (spec sec. 4)
% ---------------------------------------------------------------------------
% Dates always render in the right-hand column at body size and body colour --
% one canonical treatment, everywhere (spec 2.3).
\newcommand{\cv@dates}[1]{{\normalfont\normalsize\color{black}#1}}

% Institution / venue name. Bold, and link-coloured because it links out.
% All-or-nothing: either every use links or none does, since a mix leaves
% coloured names beside black ones. To drop linking, redefine as {\textbf{#2}}.
\newcommand{\cvinst}[2]{\textbf{\href{#1}{#2}}}

% Plain semantic hyperlink, for advisors and venues.
\newcommand{\cvlink}[2]{\href{#1}{#2}}

% \cvevent{Role or Title}{Institution}{Mon YYYY -- Mon YYYY}{Optional subtitle}
\newcommand{\cvevent}[4]{%
  \cv@entrystart{\cv@entryneed}%
  \begin{tabularx}{\linewidth}{@{}X r@{}}
    % Comma, not an en-dash. The en-dash is the date-range marker, and it also
    % appeared as the title/institution separator on the very same line, so one
    % mark carried two meanings. A comma has no such collision and matches the
    % separator already used by \cvteaching and the honours entries.
    % \cvproject keeps its en-dash: it carries no date, so nothing collides.
    \textbf{#1}\ifblank{#2}{}{, #2} & \cv@dates{#3}
  \end{tabularx}%
  \par\nobreak
  \ifblank{#4}{}{{\itshape #4}\par\nobreak}%
}

% \cvadvisor{Name} -- an advisor credit, always on its own line directly under
% the entry heading. A macro rather than prose in the subtitle argument so the
% "Advisor:" label is defined once, and so an entry can carry both a subtitle
% (e.g. a thesis title) and an advisor without the two running together.
% Optional argument appends a note after the advisor, separated by a middot --
% for funding attached to the appointment. Kept in the class so content files
% never have to spell out the separator or its spacing.
\newcommand{\cvadvisor}[2][]{%
  {\itshape Advisor: #2\ifblank{#1}{}{\ \textperiodcentered\ #1}}\par\nobreak}

% \cvpublication[venue note]{Title}{Author list}{Venue}{Year}
%
% The optional note is set upright in parentheses immediately after the italic
% venue, on the same line -- for an acceptance rate or similar venue-strength
% figure. Keeping it in the class rather than inside the venue argument means
% the content file never has to switch fonts by hand.
\newcommand{\cvpublication}[5][]{%
  \cv@entrystart{\cv@entryneed}%
  \begin{tabularx}{\linewidth}{@{}X r@{}}
    \textbf{#2} & \cv@dates{#5}
  \end{tabularx}%
  \par\nobreak
  % Author list and venue are both optional: a submission still under review
  % may have neither disclosable, and empty arguments must not leave blank
  % lines behind.
  \ifblank{#3}{}{#3\par\nobreak}%
  \ifblank{#4}{}{{\itshape #4}\ifblank{#1}{}{ (#1)}\par\nobreak}%
}

% Bold the author's own name in author lists -- applied through one macro so it
% is uniform everywhere.
\newcommand{\cvme}{\textbf{P.~Barahimi}}

% \cvhonor{Year}{Award}{Detail} -- a row of the cvhonorlist tabular.
% Spec sec. 4 puts the year first in the signature; spec 2.3 requires every
% single-point date to be right-aligned. 2.3 wins on rendering.
% These are all single-line entries, so they are set as one tabular rather than
% as separate entries -- \cvEntrySkip between four one-line rows reads as a gap,
% not as rhythm.
\newenvironment{cvhonorlist}
  {\cv@entrystart{\cv@entryneed}%
   \renewcommand{\arraystretch}{1.3}%
   \tabularx{\linewidth}{@{}X r@{}}}
  {\endtabularx\par}
% Award names are deliberately NOT bold. XCharter's bold is heavy, and four
% consecutive bold rows read as a slab; the right-aligned year column already
% gives each row its structure.
\newcommand{\cvhonor}[3]{%
  #2\ifblank{#3}{}{, \textit{#3}} & \cv@dates{#1} \\}

% \cvproject{Title}{Stack}{Optional subtitle}
% Projects carry no dates, so the right-hand column stays empty: it is
% reserved for dates and nothing else.
\newcommand{\cvproject}[3]{%
  \cv@entrystart{\cv@entryneed}%
  \textbf{#1}\ifblank{#2}{}{ \textendash\ #2}\par\nobreak
  \ifblank{#3}{}{{\itshape #3}\par\nobreak}%
}

% Teaching Experience: a full-width tabular, course left, dates right
% (spec 2.4 -- explicitly NOT a floating two-column layout).
%
% Role and course share one column. As three columns the role sat in a narrow
% left strip and the short course titles left a canyon of white before the
% right-aligned dates; merging them lengthens the left block and closes most of
% that gap, while keeping dates on the same right edge as every other section.
\newenvironment{cvteachinglist}
  {\cv@entrystart{\cv@entryneed}%
   \renewcommand{\arraystretch}{1.25}%
   \tabularx{\linewidth}{@{}X r@{}}}
  {\endtabularx\par}
\newcommand{\cvteaching}[3]{\textbf{#1}, \emph{#2} & \cv@dates{#3} \\}

% Skills: label/value rows in one full-width tabular.
\newenvironment{cvskilllist}
  {\cv@entrystart{\cv@entryneed}%
   \renewcommand{\arraystretch}{1.3}%
   % Labels in small caps rather than bold: the column already separates them
   % from the values, so they need distinction, not weight.
   \tabularx{\linewidth}{@{}>{\scshape}l @{\hspace{1em}} X@{}}}
  {\endtabularx\par}
\newcommand{\cvskill}[2]{#1 & #2 \\}

% Bullets.
\newenvironment{cvitems}
  {\begin{itemize}[leftmargin=1.2em,topsep=1.5pt,partopsep=0pt,parsep=0pt,%
                   itemsep=1.5pt,label=\textbullet]}
  {\end{itemize}}
\newcommand{\cvitem}[1]{\item #1}

% Last-updated stamp, pushed to the foot of the final page.
%
% Uses the same abbreviated Mon YYYY vocabulary as every other date in the
% document (spec 2.3) rather than \today's "August 12, 2026" -- one date
% vocabulary everywhere, page furniture included. Set in the same muted grey as
% the running header, since it is furniture rather than content.
\newcommand{\cv@monthname}{%
  \ifcase\month\or Jan\or Feb\or Mar\or Apr\or May\or Jun\or
  Jul\or Aug\or Sep\or Oct\or Nov\or Dec\fi}

\newcommand{\cvlastupdated}{%
  \par\vfill
  {\centering\footnotesize\color{cvmuted}%
   Last updated: \cv@monthname~\the\year\par}%
}

% A one-line framing statement for an entry, set between the heading block and
% the bullets: what the work was about, where the bullets are what was done.
% Roman rather than italic, so it reads as content and not as another metadata
% line alongside the subtitle and advisor credit.
\newcommand{\cvsummary}[1]{#1\par\nobreak}

% A single free-standing paragraph of prose.
% Limited right-skip locally, unlike the document default: with infinite
% stretch TeX has no reason to let microtype compress a line, so a prose block
% a hair wider than the measure wraps instead of being squeezed onto one line.
% Bounded stretch restores that pressure. Safe here because the block is plain
% prose with no unbreakable tokens to overflow.
\newcommand{\cvprose}[1]{%
  \cv@entrystart{2\baselineskip}%
  {\rightskip=0pt plus 2em #1\par}%
}

% ---------------------------------------------------------------------------
% Typography helpers (spec 2.6)
% ---------------------------------------------------------------------------
% Ordinals in TEXT mode. The reference PDF rendered "1st" in math italic
% (CMMI8); \cvordinal makes that impossible to reproduce by accident.
\newcommand{\cvordinal}[2]{#1\textsuperscript{#2}}

% "approximately" -- an upright text tilde, never a math \sim.
\newcommand{\cvapprox}{\textasciitilde}

% Language names whose glyphs carry sidebearings meant for standalone symbols.
% In XCharter, "C\#" sets as "C #" and "C++" as "C + +"; the kerns close the
% gaps so each reads as one token. Values tuned by eye at 300 dpi.
\newcommand{\Csharp}{C\kern-0.06em\#}
\newcommand{\Cpp}{C\kern-0.09em+\kern-0.11em+}

% Visible placeholder for an unresolved gap; renders as [TODO: ...] in the PDF.
% Grep for \cvtodo before publishing.
\newcommand{\cvtodo}[1]{\textit{[TODO: #1]}}

\endinput
