"""
Gera a apresentacao NIMBUS CODE (4 slides) em PPTX com graficos nativos
editaveis (python-pptx ChartData), para uso em apresentacao institucional
(ex.: Microsoft Summit).

Dados reais extraidos ao vivo do repositorio
venha-pra-nuvem/nimbus-code em 2026-08-20 (ver
nimbus-code-resumo-executivo.md para o detalhamento e fontes).
"""
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE, XL_LEGEND_POSITION
from pptx.enum.shapes import MSO_SHAPE
import copy

# ---------------------------------------------------------------- palette --
NAVY = RGBColor(0x0B, 0x1E, 0x3D)      # dark navy background
BLUE = RGBColor(0x2B, 0x6C, 0xE0)      # primary accent (MS-ish blue)
CYAN = RGBColor(0x34, 0xC7, 0xC7)      # secondary accent
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
LIGHT = RGBColor(0xE8, 0xEE, 0xF7)
GRAY = RGBColor(0x8A, 0x94, 0xA6)
GREEN = RGBColor(0x3D, 0xB8, 0x6A)
ORANGE = RGBColor(0xE8, 0x9B, 0x2E)

SLIDE_W = Inches(13.333)
SLIDE_H = Inches(7.5)

prs = Presentation()
prs.slide_width = SLIDE_W
prs.slide_height = SLIDE_H
BLANK = prs.slide_layouts[6]


def add_bg(slide, color=NAVY):
    rect = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, SLIDE_W, SLIDE_H)
    rect.fill.solid()
    rect.fill.fore_color.rgb = color
    rect.line.fill.background()
    rect.shadow.inherit = False
    # send to back
    slide.shapes._spTree.remove(rect._element)
    slide.shapes._spTree.insert(2, rect._element)
    return rect


def add_text(slide, left, top, width, height, text, size=18, color=WHITE,
             bold=False, align=PP_ALIGN.LEFT, font="Segoe UI", italic=False,
             anchor=MSO_ANCHOR.TOP, line_spacing=None):
    box = slide.shapes.add_textbox(left, top, width, height)
    tf = box.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anchor
    lines = text.split("\n")
    for i, line in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.text = line
        p.alignment = align
        if line_spacing:
            p.line_spacing = line_spacing
        for run in p.runs:
            run.font.size = Pt(size)
            run.font.bold = bold
            run.font.italic = italic
            run.font.name = font
            run.font.color.rgb = color
    return box


def add_bullets(slide, left, top, width, height, items, size=14, color=LIGHT,
                 marker_color=CYAN, bold_lead=True, gap_pt=8):
    box = slide.shapes.add_textbox(left, top, width, height)
    tf = box.text_frame
    tf.word_wrap = True
    for i, item in enumerate(items):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.space_after = Pt(gap_pt)
        if isinstance(item, tuple):
            lead, rest = item
            r1 = p.add_run()
            r1.text = f"\u25B8 {lead}  "
            r1.font.size = Pt(size)
            r1.font.bold = True
            r1.font.color.rgb = marker_color
            r1.font.name = "Segoe UI"
            r2 = p.add_run()
            r2.text = rest
            r2.font.size = Pt(size)
            r2.font.color.rgb = color
            r2.font.name = "Segoe UI"
        else:
            r1 = p.add_run()
            r1.text = f"\u25B8 {item}"
            r1.font.size = Pt(size)
            r1.font.color.rgb = color
            r1.font.name = "Segoe UI"
    return box


def add_kicker(slide, text):
    add_text(slide, Inches(0.6), Inches(0.35), Inches(8), Inches(0.4), text,
              size=14, color=CYAN, bold=True)


def add_footer(slide, page_no):
    add_text(slide, Inches(0.6), Inches(7.08), Inches(6), Inches(0.35),
              "NIMBUS CODE \u2014 Governan\u00e7a de IA + Humano no GitHub",
              size=9, color=GRAY)
    add_text(slide, Inches(12.3), Inches(7.08), Inches(0.6), Inches(0.35),
              str(page_no), size=9, color=GRAY, align=PP_ALIGN.RIGHT)


def style_chart_text(chart, size=11, color=LIGHT):
    try:
        chart.font.size = Pt(size)
        chart.font.color.rgb = color
    except Exception:
        pass


# =====================================================================
# SLIDE 1 -- TITLE
# =====================================================================
s1 = prs.slides.add_slide(BLANK)
add_bg(s1, NAVY)

# accent bar
bar = s1.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, Inches(4.55), Inches(4.2), Inches(0.12))
bar.fill.solid(); bar.fill.fore_color.rgb = CYAN; bar.line.fill.background()

add_text(s1, Inches(0.9), Inches(2.35), Inches(11.5), Inches(1.4),
          "NIMBUS CODE", size=64, color=WHITE, bold=True)
add_text(s1, Inches(0.95), Inches(3.55), Inches(11), Inches(1.0),
          "Da ideia ao c\u00f3digo funcionando \u2014 com IA supervisionada por humano,\n"
          "direto no GitHub que seu time j\u00e1 usa",
          size=22, color=LIGHT)
add_text(s1, Inches(0.95), Inches(6.35), Inches(10), Inches(0.5),
          "Apresenta\u00e7\u00e3o de Produto \u2014 Microsoft Summit",
          size=15, color=CYAN, bold=True)
add_text(s1, Inches(0.95), Inches(6.75), Inches(10), Inches(0.4),
          "Baseado em GitHub Spec-Kit + GitHub Copilot + GitHub Enterprise",
          size=12, color=GRAY, italic=True)

# small decorative shapes (nodes/graph motif)
import random
random.seed(7)
for i in range(5):
    x = Inches(9.3 + i * 0.55)
    y = Inches(1.0 + (i % 2) * 0.5)
    dot = s1.shapes.add_shape(MSO_SHAPE.OVAL, x, y, Inches(0.18), Inches(0.18))
    dot.fill.solid(); dot.fill.fore_color.rgb = BLUE if i % 2 else CYAN
    dot.line.fill.background()

# =====================================================================
# SLIDE 2 -- O PROBLEMA
# =====================================================================
s2 = prs.slides.add_slide(BLANK)
add_bg(s2, WHITE)

add_kicker_bar = s2.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, SLIDE_W, Inches(1.15))
add_kicker_bar.fill.solid(); add_kicker_bar.fill.fore_color.rgb = NAVY
add_kicker_bar.line.fill.background()
add_text(s2, Inches(0.6), Inches(0.28), Inches(10), Inches(0.45),
          "O PROBLEMA", size=16, color=CYAN, bold=True)
add_text(s2, Inches(0.6), Inches(0.62), Inches(11.5), Inches(0.5),
          "Adotar IA generativa em escala sem governan\u00e7a gera risco, custo oculto e conhecimento perdido",
          size=16, color=WHITE)

problems = [
    ("Sem trilha de auditoria", "Agentes aut\u00f4nomos alteram c\u00f3digo fora do escopo, sem revis\u00e3o clara nem rastreabilidade de decis\u00e3o."),
    ("Custo de IA sem crit\u00e9rio", "Modelo mais caro usado para qualquer tarefa, da corre\u00e7\u00e3o trivial \u00e0 arquitetura cr\u00edtica."),
    ("Conhecimento se perde", "O mesmo erro se repete; solu\u00e7\u00f5es j\u00e1 resolvidas s\u00e3o reinventadas a cada nova sess\u00e3o."),
    ("Backlog sem hierarquia", "Centenas de itens de trabalho no GitHub sem estrutura clara de prioridade e responsabilidade."),
    ("Risco de compliance", "Sem guardrails, agentes podem pular verifica\u00e7\u00f5es de seguran\u00e7a (segredos, backup, criptografia)."),
    ("ROI dif\u00edcil de medir", "Custo de IA e horas humanas n\u00e3o s\u00e3o rastreados lado a lado."),
]
colw = Inches(3.75)
colh = Inches(2.35)
x0, y0 = Inches(0.6), Inches(1.55)
gap = Inches(0.15)
for idx, (title, desc) in enumerate(problems):
    col = idx % 3
    row = idx // 3
    x = Emu(x0 + col * (colw + gap))
    y = Emu(y0 + row * (colh + gap))
    card = s2.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, x, y, colw, colh)
    card.fill.solid(); card.fill.fore_color.rgb = LIGHT
    card.line.color.rgb = RGBColor(0xC7, 0xD3, 0xE6); card.line.width = Pt(0.75)
    card.shadow.inherit = False
    tf = card.text_frame
    tf.word_wrap = True
    tf.margin_left = Inches(0.18); tf.margin_right = Inches(0.18)
    tf.margin_top = Inches(0.16)
    p = tf.paragraphs[0]
    p.text = title
    p.runs[0].font.size = Pt(15); p.runs[0].font.bold = True
    p.runs[0].font.color.rgb = NAVY; p.runs[0].font.name = "Segoe UI"
    p2 = tf.add_paragraph()
    p2.text = desc
    p2.runs[0].font.size = Pt(11.5); p2.runs[0].font.color.rgb = RGBColor(0x33, 0x3D, 0x4D)
    p2.runs[0].font.name = "Segoe UI"
    p2.space_before = Pt(6)

add_footer(s2, 2)

# =====================================================================
# SLIDE 3 -- COMO FUNCIONA: da ideia ao codigo funcionando, passo a passo
# =====================================================================
s3 = prs.slides.add_slide(BLANK)
add_bg(s3, WHITE)
bar3 = s3.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, SLIDE_W, Inches(1.15))
bar3.fill.solid(); bar3.fill.fore_color.rgb = NAVY; bar3.line.fill.background()
add_text(s3, Inches(0.6), Inches(0.28), Inches(10), Inches(0.45),
          "COMO FUNCIONA", size=16, color=CYAN, bold=True)
add_text(s3, Inches(0.6), Inches(0.62), Inches(11.8), Inches(0.5),
          "Da ideia ao c\u00f3digo funcionando em 5 passos \u2014 a IA executa, o humano sempre decide",
          size=16, color=WHITE)

# 5-step functional flow (spec -> plan -> tasks -> code -> human approval)
steps = [
    ("1", "Voc\u00ea descreve\no que quer", "Em linguagem natural, sem escrever c\u00f3digo nem jarg\u00e3o t\u00e9cnico", "HUMANO"),
    ("2", "A IA monta\no plano t\u00e9cnico", "Arquitetura, riscos e o que precisa ser testado \u2014 pronto para revis\u00e3o", "IA"),
    ("3", "A IA quebra em\ntarefas execut\u00e1veis", "Checklist claro e priorizado \u2014 nada fica amb\u00edguo", "IA"),
    ("4", "A IA escreve o\nc\u00f3digo e abre o PR", "Pull Request pronto, testado e documentado \u2014 nunca direto em produ\u00e7\u00e3o", "IA"),
    ("5", "Voc\u00ea revisa\ne aprova", "Nada vai ao ar sem revis\u00e3o humana \u2014 sempre", "HUMANO"),
]
n = len(steps)
margin = Inches(0.55)
gap = Inches(0.12)
avail = Emu(SLIDE_W - 2 * margin - (n - 1) * gap)
bw = Emu(avail / n)
bh = Inches(2.55)
by = Inches(1.85)
for i, (num, title, desc, who) in enumerate(steps):
    bx = Emu(margin + i * (bw + gap))
    is_human = who == "HUMANO"
    fillcolor = ORANGE if is_human else BLUE
    card = s3.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, bx, by, bw, bh)
    card.fill.solid(); card.fill.fore_color.rgb = fillcolor
    card.line.fill.background()
    card.shadow.inherit = False
    tf = card.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = MSO_ANCHOR.TOP
    tf.margin_left = Inches(0.14); tf.margin_right = Inches(0.14)
    tf.margin_top = Inches(0.16)
    p0 = tf.paragraphs[0]
    p0.text = num
    p0.alignment = PP_ALIGN.CENTER
    p0.runs[0].font.size = Pt(22); p0.runs[0].font.bold = True
    p0.runs[0].font.color.rgb = WHITE; p0.runs[0].font.name = "Segoe UI"
    p1 = tf.add_paragraph()
    p1.text = title
    p1.alignment = PP_ALIGN.CENTER
    p1.space_before = Pt(4)
    p1.runs[0].font.size = Pt(13.5); p1.runs[0].font.bold = True
    p1.runs[0].font.color.rgb = WHITE; p1.runs[0].font.name = "Segoe UI"
    p2 = tf.add_paragraph()
    p2.text = desc
    p2.alignment = PP_ALIGN.CENTER
    p2.space_before = Pt(8)
    p2.runs[0].font.size = Pt(10.5); p2.runs[0].font.color.rgb = WHITE
    p2.runs[0].font.name = "Segoe UI"
    p3 = tf.add_paragraph()
    p3.text = who
    p3.alignment = PP_ALIGN.CENTER
    p3.space_before = Pt(10)
    p3.runs[0].font.size = Pt(10); p3.runs[0].font.bold = True
    p3.runs[0].font.color.rgb = NAVY if is_human else RGBColor(0xD8, 0xE6, 0xFF)
    p3.runs[0].font.name = "Segoe UI"
    # arrow connector between steps
    if i < n - 1:
        ax = Emu(bx + bw + Emu(Inches(0.01)))
        arrow = s3.shapes.add_shape(MSO_SHAPE.CHEVRON, ax, Emu(by + bh // 2 - Inches(0.12)), gap, Inches(0.24))
        arrow.fill.solid(); arrow.fill.fore_color.rgb = GRAY
        arrow.line.fill.background()

add_text(s3, Inches(0.6), Inches(4.65), Inches(12.1), Inches(0.45),
          "O resultado: o que hoje leva dias de v\u00e1rias idas e vindas vira um ciclo cont\u00ednuo,\n"
          "sempre com um Pull Request revis\u00e1vel no final \u2014 nunca uma caixa-preta.",
          size=14, color=RGBColor(0x33, 0x3D, 0x4D), align=PP_ALIGN.CENTER, italic=True)

# functional guardrail callouts (still no tech jargon)
guardrails = [
    "IA nunca faz merge sozinha \u2014 sempre um Pull Request esperando aprova\u00e7\u00e3o humana",
    "Cada entrega registra o que j\u00e1 deu certo antes e evita repetir o que deu errado",
    "O esfor\u00e7o de IA se ajusta ao tamanho da tarefa \u2014 nada de usar um canh\u00e3o para matar mosca",
]
gcard_y = Inches(5.35)
gcard_h = Inches(1.55)
gcard_w = Inches(3.95)
gcard_gap = Inches(0.15)
gcard_x0 = Inches(0.6)
for i, txt in enumerate(guardrails):
    gx = Emu(gcard_x0 + i * (gcard_w + gcard_gap))
    gcard = s3.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, gx, gcard_y, gcard_w, gcard_h)
    gcard.fill.solid(); gcard.fill.fore_color.rgb = LIGHT
    gcard.line.color.rgb = RGBColor(0xC7, 0xD3, 0xE6); gcard.line.width = Pt(0.75)
    gcard.shadow.inherit = False
    tf = gcard.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    tf.margin_left = Inches(0.18); tf.margin_right = Inches(0.18)
    p = tf.paragraphs[0]
    p.text = txt
    p.alignment = PP_ALIGN.CENTER
    p.runs[0].font.size = Pt(12); p.runs[0].font.color.rgb = NAVY
    p.runs[0].font.name = "Segoe UI"

add_footer(s3, 3)

# =====================================================================
# SLIDE 4 -- PROVA REAL + CTA
# =====================================================================
s4 = prs.slides.add_slide(BLANK)
add_bg(s4, NAVY)
add_text(s4, Inches(0.6), Inches(0.35), Inches(10), Inches(0.45),
          "PROVA REAL \u2014 DADOS DO PROJETO EM PRODU\u00c7\u00c3O", size=16, color=CYAN, bold=True)
add_text(s4, Inches(0.6), Inches(0.72), Inches(11.5), Inches(0.5),
          "N\u00fameros extra\u00eddos ao vivo do reposit\u00f3rio nimbus-code (2026-08-20)",
          size=13, color=LIGHT)

# KPI callouts
kpis = [
    ("13", "ideias transformadas\nem planos t\u00e9cnicos"),
    ("136", "itens de trabalho\norganizados e rastre\u00e1veis"),
    ("99%", "do backlog totalmente\norganizado e priorizado"),
    ("v1.9.0", "vers\u00e3o do produto\nj\u00e1 publicada e em uso"),
]
kw, kh = Inches(2.85), Inches(1.5)
kx0, ky0 = Inches(0.6), Inches(1.4)
kgap = Inches(0.18)
for i, (num, label) in enumerate(kpis):
    x = Emu(kx0 + i * (kw + kgap))
    card = s4.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, x, ky0, kw, kh)
    card.fill.solid(); card.fill.fore_color.rgb = RGBColor(0x15, 0x2A, 0x52)
    card.line.color.rgb = BLUE; card.line.width = Pt(1)
    card.shadow.inherit = False
    tf = card.text_frame
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.text = num
    p.alignment = PP_ALIGN.CENTER
    p.runs[0].font.size = Pt(30); p.runs[0].font.bold = True
    p.runs[0].font.color.rgb = CYAN; p.runs[0].font.name = "Segoe UI"
    p2 = tf.add_paragraph()
    p2.text = label
    p2.alignment = PP_ALIGN.CENTER
    p2.runs[0].font.size = Pt(11); p2.runs[0].font.color.rgb = LIGHT
    p2.runs[0].font.name = "Segoe UI"

# real chart: features by delivery phase
chart_data2 = CategoryChartData()
chart_data2.categories = ["Em planejamento", "J\u00e1 em execu\u00e7\u00e3o\n(virou tarefa)", "Prontas, aguardando\nrevis\u00e3o final"]
chart_data2.add_series("Ideias (n\u00famero real)", (3, 9, 1))
gx2, gy2, gw2, gh2 = Inches(0.6), Inches(3.15), Inches(6.0), Inches(3.1)
gframe2 = s4.shapes.add_chart(XL_CHART_TYPE.PIE, gx2, gy2, gw2, gh2, chart_data2)
chart2 = gframe2.chart
chart2.has_legend = True
chart2.legend.position = XL_LEGEND_POSITION.BOTTOM
chart2.legend.include_in_layout = False
chart2.legend.font.size = Pt(11)
chart2.legend.font.color.rgb = LIGHT
chart2.has_title = True
chart2.chart_title.text_frame.text = "13 ideias reais transformadas em entregas"
chart2.chart_title.text_frame.paragraphs[0].runs[0].font.size = Pt(13)
chart2.chart_title.text_frame.paragraphs[0].runs[0].font.bold = True
chart2.chart_title.text_frame.paragraphs[0].runs[0].font.color.rgb = WHITE
plot2 = chart2.plots[0]
plot2.has_data_labels = True
plot2.data_labels.number_format = '0'
plot2.data_labels.number_format_is_linked = False
plot2.data_labels.font.size = Pt(12)
plot2.data_labels.font.bold = True
plot2.data_labels.font.color.rgb = WHITE
colors = [ORANGE, GREEN, CYAN]
for i, point in enumerate(plot2.series[0].points):
    point.format.fill.solid()
    point.format.fill.fore_color.rgb = colors[i % len(colors)]

# label compliance donut
chart_data3 = CategoryChartData()
chart_data3.categories = ["Organizadas", "Pendente"]
chart_data3.add_series("Itens de trabalho", (135, 1))
gx3, gy3, gw3, gh3 = Inches(6.9, ), Inches(3.15), Inches(5.9), Inches(3.1)
gframe3 = s4.shapes.add_chart(XL_CHART_TYPE.DOUGHNUT, gx3, gy3, gw3, gh3, chart_data3)
chart3 = gframe3.chart
chart3.has_legend = True
chart3.legend.position = XL_LEGEND_POSITION.BOTTOM
chart3.legend.include_in_layout = False
chart3.legend.font.size = Pt(11)
chart3.legend.font.color.rgb = LIGHT
chart3.has_title = True
chart3.chart_title.text_frame.text = "136 itens de trabalho \u2014 backlog totalmente organizado e priorizado"
chart3.chart_title.text_frame.paragraphs[0].runs[0].font.size = Pt(12.5)
chart3.chart_title.text_frame.paragraphs[0].runs[0].font.bold = True
chart3.chart_title.text_frame.paragraphs[0].runs[0].font.color.rgb = WHITE
plot3 = chart3.plots[0]
plot3.has_data_labels = True
plot3.data_labels.number_format = '0'
plot3.data_labels.number_format_is_linked = False
plot3.data_labels.font.size = Pt(12)
plot3.data_labels.font.color.rgb = WHITE
colors3 = [GREEN, ORANGE]
for i, point in enumerate(plot3.series[0].points):
    point.format.fill.solid()
    point.format.fill.fore_color.rgb = colors3[i % len(colors3)]

add_text(s4, Inches(0.6), Inches(6.42), Inches(12.1), Inches(0.6),
          "\u201cNIMBUS CODE n\u00e3o \u00e9 sobre fazer a IA escrever c\u00f3digo mais r\u00e1pido \u2014 \u00e9 sobre a empresa "
          "conseguir confiar, auditar e medir o que os agentes de IA est\u00e3o entregando.\u201d",
          size=13, color=CYAN, italic=True, align=PP_ALIGN.CENTER)

add_footer(s4, 4)

out_path = r"C:\Users\leonardo\.copilot\session-state\fad9383d-7ac9-46cd-9dc3-ebe32b8d229a\files\nimbus-code-product\NIMBUS-CODE-Apresentacao.pptx"
prs.save(out_path)
print("Saved:", out_path)
