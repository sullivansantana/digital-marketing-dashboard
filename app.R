# ============================================================
#  Marketing Insights Dashboard — shinydashboard
#  Versión lista para shinyapps.io
#
#  ESTRUCTURA DE ARCHIVOS QUE SE DEBEN SUBIR:
#    app.R
#    marketing_data.rds   <- generado con generate_data.R
#    renv.lock            <- generado con renv::snapshot()
# ============================================================

# ── 1. Paquetes (solo library(), sin install.packages) ───────
library(shiny)
library(rsconnect)
library(shinydashboard)
library(dplyr)
library(lubridate)
library(tidyr)
library(echarts4r)
library(scales)
library(DT)
library(htmltools)

# ── 2. Datos (cargados desde .rds, NO generados en runtime) ──
if (!file.exists("marketing_data.rds")) {
  stop("Archivo marketing_data.rds no encontrado.
       Ejecuta generate_data.R en tu máquina local y
       sube el .rds junto con app.R.")
}
marketing_data <- readRDS("marketing_data.rds")

# ── 3. Constantes globales ───────────────────────────────────
CHANNEL_COLORS <- c(
  "Programmatic" = "#6A0DAD",
  "Paid Search"  = "#FF4DA6",
  "Paid Social"  = "#4DB6E2",
  "Organic"      = "#FF8C00"
)

channels  <- c("Programmatic", "Paid Search", "Paid Social", "Organic")
campaigns <- c("Brand Awareness", "Winter Sale", "Spring Promotion",
               "Summer Deals", "Back to School", "Holiday Push",
               "Retargeting Campaign", "Product Launch")

# ── 4. Helpers ───────────────────────────────────────────────
fmt_dollars <- function(x) {
  x <- as.numeric(x)
  if (is.na(x)) return("$0")
  if      (abs(x) >= 1e6) paste0("$", round(x / 1e6, 2), "M")
  else if (abs(x) >= 1e3) paste0("$", round(x / 1e3, 1), "K")
  else                     paste0("$", round(x, 0))
}

fmt_num <- function(x) {
  x <- as.numeric(x)
  if (is.na(x)) return("0")
  if      (abs(x) >= 1e6) paste0(round(x / 1e6, 1), "M")
  else if (abs(x) >= 1e3) paste0(round(x / 1e3, 1), "K")
  else                     as.character(round(x, 0))
}

fmt_pct <- function(x) {
  x <- as.numeric(x)
  if (is.na(x)) return("0%")
  paste0(round(x * 100, 1), "%")
}

delta_html <- function(val, prefix = "", suffix = "") {
  val   <- as.numeric(val)
  if (is.na(val)) val <- 0
  arrow <- if (val >= 0) "\u25b2" else "\u25bc"
  col   <- if (val >= 0) "#2ecc71" else "#e74c3c"
  formatted <- paste0(prefix, abs(round(val, 2)), suffix)
  tags$span(
    style = paste0("color:", col, "; font-size:13px;"),
    arrow, " ", formatted
  )
}

kpi_card <- function(title, value, delta, delta_prefix = "", delta_suffix = "") {
  div(
    class = "kpi-card",
    p(class  = "kpi-title", title),
    h3(class = "kpi-value", value),
    delta_html(delta, delta_prefix, delta_suffix)
  )
}

# ── 5. UI ────────────────────────────────────────────────────
ui <- dashboardPage(
  skin = "purple",

  # Header 
  dashboardHeader(
    title = tags$span(
      tags$b("improvado", style = "font-size:18px; color:#fff;")
    )
  ),

  dashboardSidebar(
    width = 210,
    tags$div(
      style = "padding:14px 16px 4px; color:#aaa; font-size:11px;
               text-transform:uppercase; letter-spacing:1px;",
      "Marketing Insights"
    ),
    sidebarMenu(
      menuItem("Cross Channel",       tabName = "cross",    icon = icon("layer-group")),
      menuItem("Executive Summary",   tabName = "exec",     icon = icon("chart-bar"), selected = TRUE),
      menuItem("Channel Performance", tabName = "chanperf", icon = icon("signal")),
      menuItem("Channel Segments",    tabName = "seg",      icon = icon("chart-pie")),
      tags$hr(style = "border-color:#444; margin:10px 0;"),
      tags$div(
        style = "padding:6px 16px; color:#aaa; font-size:11px;
                 text-transform:uppercase; letter-spacing:1px;",
        "Paid Ads \u00d7 Google Analytics"
      ),
      menuItem("Paid Search",        tabName = "psearch", icon = icon("search")),
      menuItem("Paid Social",        tabName = "psocial", icon = icon("share-alt")),
      menuItem("Search Engine Opt.", tabName = "seo",     icon = icon("globe")),
      menuItem("Organic Social",     tabName = "orgsoc",  icon = icon("seedling")),
      menuItem("Programmatic",       tabName = "prog",    icon = icon("tv")),
      tags$hr(style = "border-color:#444; margin:10px 0;"),
      menuItem("eCommerce",          tabName = "ecom",    icon = icon("shopping-cart"))
    )
  ),

  dashboardBody(

    tags$head(tags$style(HTML("
      body, .content-wrapper, .main-sidebar { background:#f4f6fb !important; }
      .skin-purple .main-header .logo,
      .skin-purple .main-header .navbar      { background:#1e1b4b !important; border:none; }
      .skin-purple .main-sidebar             { background:#1a1a2e !important; }
      .skin-purple .sidebar a                { color:#ccc !important; }
      .skin-purple .sidebar-menu > li.active > a,
      .skin-purple .sidebar-menu > li:hover > a { background:#6A0DAD !important; color:#fff !important; }
      .content-wrapper { padding:18px 20px; }

      .filter-bar { display:flex; gap:10px; margin-bottom:18px; flex-wrap:wrap; }
      .filter-bar .form-group { margin:0; }
      .filter-bar select, .filter-bar .form-control {
        border-radius:20px; border:1px solid #ddd;
        padding:4px 14px; font-size:13px; height:34px; background:#fff;
      }

      .kpi-row  { display:flex; gap:14px; margin-bottom:14px; flex-wrap:wrap; }
      .kpi-card {
        background:#fff; border-radius:12px; padding:16px 20px 12px;
        flex:1; min-width:160px; box-shadow:0 1px 6px rgba(0,0,0,.07);
        border-top:3px solid #6A0DAD;
      }
      .kpi-title { font-size:12px; color:#888; margin:0 0 4px;
                   text-transform:uppercase; letter-spacing:.5px; }
      .kpi-value { font-size:26px; font-weight:700; margin:0 0 4px; color:#1a1a2e; }

      .dash-panel {
        background:#fff; border-radius:12px; padding:16px 20px;
        box-shadow:0 1px 6px rgba(0,0,0,.07); margin-bottom:14px;
      }
      .panel-title {
        font-size:15px; font-weight:700; color:#1a1a2e;
        margin:0 0 12px; display:flex; align-items:center; gap:8px;
      }
      .panel-title .icon-badge {
        width:28px; height:28px; border-radius:50%;
        background:#f0e6ff; display:inline-flex;
        align-items:center; justify-content:center;
        color:#6A0DAD; font-size:13px;
      }

      table.dataTable thead th {
        font-size:11px; color:#aaa; text-transform:uppercase;
        font-weight:600; border-bottom:1px solid #eee !important;
      }
      table.dataTable tbody td { font-size:13px; color:#333; }
      table.dataTable tbody tr:hover { background:#f9f0ff !important; }
      .dataTables_wrapper .dataTables_filter,
      .dataTables_wrapper .dataTables_length,
      .dataTables_wrapper .dataTables_info,
      .dataTables_wrapper .dataTables_paginate { display:none; }
    "))),

    tabItems(

      # ── Executive Summary ──────────────────────────────────
      tabItem(
        tabName = "exec",

        tags$div(
          class = "filter-bar",
          selectInput("sel_source",   "Data Source",
                      c("All", sort(unique(marketing_data$data_source))),
                      width = "180px"),
          selectInput("sel_channel",  "Channel",
                      c("All", channels),
                      width = "150px"),
          selectInput("sel_campaign", "Campaign",
                      c("All", campaigns),
                      width = "200px"),
          # label 
          dateRangeInput("sel_dates", label = "",
                         start = "2023-01-01", end = "2023-12-31",
                         min   = "2022-01-01", max = "2023-12-31",
                         width = "250px")
        ),

        uiOutput("kpi_row1"),
        uiOutput("kpi_row2"),

        fluidRow(
          column(8,
            div(class = "dash-panel",
                echarts4rOutput("spend_line", height = "340px"))
          ),
          column(4,
            div(class = "dash-panel",
                div(class = "panel-title",
                    span(class = "icon-badge", icon("signal")),
                    "Channel Performance"),
                DTOutput("tbl_channel")),
            div(class = "dash-panel",
                div(class = "panel-title",
                    span(class = "icon-badge", icon("database")),
                    "Data Source Performance"),
                DTOutput("tbl_source")),
            div(class = "dash-panel",
                div(class = "panel-title",
                    span(class = "icon-badge", icon("bullhorn")),
                    "Campaign Performance"),
                DTOutput("tbl_campaign"))
          )
        )
      ),

      # Placeholder tabs
      tabItem(tabName = "cross",    h3("Cross Channel \u2014 coming soon")),
      tabItem(tabName = "chanperf", h3("Channel Performance \u2014 coming soon")),
      tabItem(tabName = "seg",      h3("Channel Segments \u2014 coming soon")),
      tabItem(tabName = "psearch",  h3("Paid Search \u2014 coming soon")),
      tabItem(tabName = "psocial",  h3("Paid Social \u2014 coming soon")),
      tabItem(tabName = "seo",      h3("Search Engine Opt. \u2014 coming soon")),
      tabItem(tabName = "orgsoc",   h3("Organic Social \u2014 coming soon")),
      tabItem(tabName = "prog",     h3("Programmatic \u2014 coming soon")),
      tabItem(tabName = "ecom",     h3("eCommerce \u2014 coming soon"))
    )
  )
)

# ── 6. Server ────────────────────────────────────────────────
server <- function(input, output, session) {

  # Datos del período seleccionado
  filtered <- reactive({
    req(input$sel_dates)   
    d <- marketing_data |>
      filter(date >= input$sel_dates[1], date <= input$sel_dates[2])
    if (input$sel_source   != "All") d <- filter(d, data_source == input$sel_source)
    if (input$sel_channel  != "All") d <- filter(d, channel     == input$sel_channel)
    if (input$sel_campaign != "All") d <- filter(d, campaign    == input$sel_campaign)
    d
  })

  # Período anterior (mismo span, desplazado hacia atrás)
  prior <- reactive({
    req(input$sel_dates)
    span <- as.numeric(difftime(input$sel_dates[2], input$sel_dates[1],
                                units = "days")) + 1
    d <- marketing_data |>
      filter(date >= input$sel_dates[1] - span,
             date <  input$sel_dates[1])
    if (input$sel_source   != "All") d <- filter(d, data_source == input$sel_source)
    if (input$sel_channel  != "All") d <- filter(d, channel     == input$sel_channel)
    if (input$sel_campaign != "All") d <- filter(d, campaign    == input$sel_campaign)
    d
  })

  # KPIs calculados
  kpi <- reactive({
    cur <- filtered()
    prv <- prior()

    safe_div <- function(a, b) if (!is.na(b) && b > 0) a / b else 0

    ctr_val <- safe_div(sum(cur$clicks),       sum(cur$impressions))
    cpc_val <- safe_div(sum(cur$spend),         sum(cur$clicks, na.rm = TRUE))
    cvr_val <- safe_div(sum(cur$conversions),   sum(cur$clicks, na.rm = TRUE))

    list(
      spend       = sum(cur$spend),
      d_spend     = sum(cur$spend)       - sum(prv$spend),
      impressions = sum(cur$impressions),
      d_impr      = sum(cur$impressions) - sum(prv$impressions),
      ctr         = ctr_val,
      d_ctr       = ctr_val - safe_div(sum(prv$clicks), sum(prv$impressions)),
      cpc         = cpc_val,
      d_cpc       = cpc_val - safe_div(sum(prv$spend),  sum(prv$clicks, na.rm = TRUE)),
      conversions = sum(cur$conversions),
      d_conv      = sum(cur$conversions) - sum(prv$conversions),
      cvr         = cvr_val,
      d_cvr       = cvr_val - safe_div(sum(prv$conversions), sum(prv$clicks, na.rm = TRUE))
    )
  })

  output$kpi_row1 <- renderUI({
    k <- kpi()
    div(class = "kpi-row",
        kpi_card("Spend",       fmt_dollars(k$spend),   k$d_spend,     "$", ""),
        kpi_card("Impressions", fmt_num(k$impressions), k$d_impr,      "",  ""),
        kpi_card("CTR",         fmt_pct(k$ctr),         k$d_ctr * 100, "",  "%"),
        kpi_card("CPC",         fmt_dollars(k$cpc),     k$d_cpc,       "$", "")
    )
  })

  output$kpi_row2 <- renderUI({
    k   <- kpi()
    cur <- filtered()
    prv <- prior()
    vv_cur <- round(sum(cur$clicks) * 3)
    vv_prv <- round(sum(prv$clicks) * 3)
    div(class = "kpi-row",
        kpi_card("Clicks",          fmt_num(sum(cur$clicks)),  sum(cur$clicks) - sum(prv$clicks), "", ""),
        kpi_card("Conversions",     fmt_num(k$conversions),    k$d_conv,                          "", ""),
        kpi_card("Conversion Rate", fmt_pct(k$cvr),            k$d_cvr * 100,                     "", "%"),
        kpi_card("Video Views",     fmt_num(vv_cur),           vv_cur - vv_prv,                   "", "")
    )
  })

  output$spend_line <- renderEcharts4r({
    df <- filtered() |>
      mutate(
        month   = floor_date(as.Date(date), "month"),
        channel = as.character(channel)
      ) |>
      group_by(month, channel) |>
      summarise(spend = sum(spend, na.rm = TRUE), .groups = "drop") |>
      arrange(month) |>
      mutate(
        month_lab = format(month, "%b %Y"),
        channel   = factor(channel, levels = names(CHANNEL_COLORS))
      )

    # Guard: sin datos devolvemos un widget vacío en vez de error
    if (nrow(df) == 0) {
      return(
        data.frame(x = character(0), y = numeric(0)) |>
          e_charts(x) |>
          e_line(y)
      )
    }

    df |>
      group_by(channel) |>
      e_charts(month_lab) |>
      e_line(spend, symbolSize = 8, lineStyle = list(width = 3)) |>
      e_color(unname(CHANNEL_COLORS)) |>
      e_y_axis(
        axisLabel = list(
          formatter = htmlwidgets::JS(
            "function(v){ return '$'+(v/1e6).toFixed(1)+'M'; }"
          )
        )
      ) |>
      e_x_axis(axisLabel = list(rotate = 45)) |>
      e_legend(top = 0) |>
      e_theme("walden") |>
      e_tooltip(
        trigger = "axis",
        formatter = htmlwidgets::JS("
          function(params){
            var s = '<b>' + params[0].name + '</b><br/>';
            params.forEach(function(p){
              var raw = Array.isArray(p.value) ? p.value[1] : p.value;
              var v = (raw === undefined || raw === null || isNaN(raw))
                        ? 'N/A'
                        : '$' + (raw / 1e6).toFixed(2) + 'M';
              s += p.marker + ' ' + p.seriesName + ': ' + v + '<br/>';
            });
            return s;
          }
        ")
      )
  })

  # Helper interno para las tres tablas de rendimiento
  make_perf_table <- function(df, group_col, label) {
    df |>
      group_by(!!rlang::sym(group_col)) |>
      summarise(
        Impressions = sum(impressions),
        CTR         = mean(ctr),
        .groups     = "drop"
      ) |>
      rename(!!label := !!rlang::sym(group_col)) |>
      mutate(
        Impressions = paste0(round(Impressions / 1e3, 1), "K"),
        CTR         = paste0(round(CTR * 100, 2), "%")
      ) |>
      datatable(
        rownames = FALSE,
        options  = list(dom = "t", ordering = FALSE),
        class    = "compact hover"
      )
  }

  output$tbl_channel  <- renderDT(make_perf_table(filtered(), "channel",     "Channel"))
  output$tbl_source   <- renderDT(make_perf_table(filtered(), "data_source", "Source"))
  output$tbl_campaign <- renderDT(make_perf_table(filtered(), "campaign",    "Campaign"))
}

# ── 7. Lanzar la app ─────────────────────────────────────────
shinyApp(ui, server)
