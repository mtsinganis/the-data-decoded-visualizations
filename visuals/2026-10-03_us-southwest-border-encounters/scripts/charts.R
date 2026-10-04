source(file.path(project,'scripts/frame.R'))
base <- theme_minimal(base_family=regular_alias,base_size=11)+
 theme(axis.title.x=element_blank(),axis.title.y=element_text(colour=support,size=10),axis.text=element_text(colour=support,size=10),legend.position='none',
 panel.grid.minor=element_blank(),panel.grid.major.x=element_blank(),panel.grid.major.y=element_line(colour='#E6E8EB',linewidth=.3),
 plot.margin=margin(8,4,6,0),panel.background=element_rect(fill='white',colour=NA),plot.background=element_rect(fill='white',colour=NA))
if (!exists('render_target') || render_target != 'monthly-timeline') {
 chart_index <- term_indexed |> filter(!is.na(index))
 upper <- 470
 term_cols <- c(trump_first=crimson,biden=blue,trump_second=crimson)
 term_styles <- c(trump_first='22',biden='solid',trump_second='solid')
 ends <- chart_index |> group_by(term_id) |> slice_max(term_month,n=1,with_ties=FALSE) |> ungroup() |>
  mutate(label_x=term_month+if_else(term_id=='trump_second',.54,-.54),
   label_y=case_when(term_id=='trump_first' ~ index+30,term_id=='biden' ~ 40,TRUE ~ 48),
   align=if_else(term_id=='trump_second',0,1),
   label_vjust=if_else(label_y>index,0,1),
   connector_y=label_y+if_else(label_y>index,if_else(term_id=='trump_second',34,14),-14),
   display_label=if_else(term_id=='trump_second',paste0(term,'\n(through Aug 2026)'),term))
 p <- ggplot(chart_index,aes(term_month,index,group=term_id,colour=term_id))+
  geom_vline(xintercept=c(12.5,24.5,36.5),colour='#EDF0F3',linewidth=.25)+
  geom_hline(yintercept=100,colour='#B9BEC7',linewidth=.4)+
  geom_line(aes(linetype=term_id),linewidth=.85)+
  geom_point(data=chart_index |> filter(term_id=='trump_second' & term_month==20),size=1.5)+
  geom_segment(data=ends,aes(x=term_month,xend=term_month,y=index,yend=connector_y),linewidth=.3)+
  geom_text(data=ends,aes(x=label_x,y=label_y,label=display_label,hjust=align,vjust=label_vjust),family=bold_alias,size=11.5/(72.27/25.4),lineheight=1.1)+
  annotate('segment',x=29,xend=29,y=426.7499367,yend=464,colour=crimson,linewidth=.3)+
  annotate('text',x=28.46,y=431,label='2019 surge: predominantly\nCentral American families.',hjust=1,vjust=0,family=regular_alias,size=11.5/(72.27/25.4),lineheight=1.1,colour=crimson)+
  annotate('label',x=2,y=118,label='Starting January = 100',hjust=0,family=regular_alias,size=11.5/(72.27/25.4),
   colour=support,fill='white',linewidth=0,label.padding=unit(.06,'lines'))+
  scale_colour_manual(values=term_cols)+scale_linetype_manual(values=term_styles)+
  scale_x_continuous(breaks=c(6.5,18.5,30.5,42.5),labels=paste('Year',1:4),limits=c(.5,49),expand=c(0,0))+
  scale_y_continuous(name=NULL,limits=c(0,upper),breaks=seq(0,upper,100),expand=c(0,0))+base+
  theme(axis.text=element_text(size=11.5),axis.title.y=element_blank())
 stopifnot(upper>=max(chart_index$index))
 frame(p,'How southern border encounters evolved during each presidential term',
  'Average daily encounters indexed to each term\u2019s starting January = 100',
  'presidential-term-index',7.5,7.5,dpi=400,title_size=22.5,subtitle_size=14.3,footer_size=10.2,
  source_text='U.S. Customs and Border Protection \u00b7 Retrieved Oct 2026.',
  note='Lines show relative changes, not absolute encounter levels. January spans administrations and approximates the inherited level. Southwest Border Patrol only; excludes official ports of entry. Encounters count events, not unique people. Includes Title 42 expulsions (Mar 2020\u2013May 2023). Recent totals include interior apprehensions; whether earlier totals included these consistently is unconfirmed.')
}
# Timeline-only styling.
pt_mm <- function(pt) pt / (72.27/25.4)
presidencies <- tibble(date=as.Date(c('2017-01-20','2021-01-20','2025-01-20')),
 label=c('Trump \u00b7 first term','Biden','Trump \u00b7 second term'),
 from=c('From Jan 2017','From Jan 2021','From Jan 2025'),
 label_date=as.Date(c('2017-03-06','2021-03-06','2025-03-06')),align=c(0,0,0))
latest_point <- monthly |> slice_max(date,n=1,with_ties=FALSE)
peak_date_label <- format(peak$date,'%b %Y')
latest_date_label <- format(latest_point$date,'%b %Y')
peak_value <- paste0(comma(round(peak$average_daily_encounters)),' per day')
latest_value <- paste0(comma(round(latest_point$average_daily_encounters)),' per day')
timeline <- ggplot(monthly,aes(date,average_daily_encounters))+
 geom_segment(data=presidencies,aes(x=date,xend=date,y=0,yend=10000),inherit.aes=FALSE,colour='#ADB4BF',linewidth=.45)+
 geom_line(colour=blue,linewidth=.9)+
 geom_text(data=presidencies,aes(x=label_date,y=10000,label=label,hjust=align),inherit.aes=FALSE,vjust=1,family=bold_alias,size=pt_mm(11.5),colour=support)+
 geom_text(data=presidencies,aes(x=label_date,y=9530,label=from,hjust=align),inherit.aes=FALSE,vjust=1,family=regular_alias,size=pt_mm(11.5),colour=support)+
 ggtext::geom_richtext(data=tibble(date=peak$date,y=8850,label=paste0(peak_date_label,'<br><b>',peak_value,'</b>')),
 aes(x=date,y=y,label=label),inherit.aes=FALSE,hjust=.5,vjust=.5,family=regular_alias,size=pt_mm(11.5),lineheight=1.1,colour=blue,fill=NA,label.colour=NA,label.padding=unit(0,'pt'),label.margin=unit(0,'pt'))+
 annotate('segment',x=peak$date,xend=peak$date,y=8470,yend=peak$average_daily_encounters+120,colour=blue,linewidth=.35)+
 ggtext::geom_richtext(data=tibble(date=as.Date('2024-07-01'),y=1000,label=paste0('Dec 2024<br><b>',comma(round(monthly$average_daily_encounters[monthly$date==as.Date('2024-12-01')])),' per day</b>')),
 aes(x=date,y=y,label=label),inherit.aes=FALSE,hjust=1,vjust=.5,family=regular_alias,size=pt_mm(11.5),lineheight=1.1,colour=blue,fill=NA,label.colour=NA,label.padding=unit(0,'pt'),label.margin=unit(0,'pt'))+
 annotate('segment',x=as.Date('2024-07-01'),xend=as.Date('2024-12-01'),y=1370,yend=monthly$average_daily_encounters[monthly$date==as.Date('2024-12-01')]-120,colour=blue,linewidth=.35)+
 geom_point(data=latest_point,colour=blue,size=1.6)+
 ggtext::geom_richtext(data=tibble(date=latest_point$date,y=1450,label=paste0(latest_date_label,'<br><b>',latest_value,'</b>')),
 aes(x=date,y=y,label=label),inherit.aes=FALSE,hjust=.5,vjust=.5,family=regular_alias,size=pt_mm(11.5),lineheight=1.1,colour=blue,fill=NA,label.colour=NA,label.padding=unit(0,'pt'),label.margin=unit(0,'pt'))+
 annotate('segment',x=latest_point$date,xend=latest_point$date,y=1070,yend=latest_point$average_daily_encounters+120,colour=blue,linewidth=.35)+
 scale_x_date(breaks=as.Date(c('2017-01-01','2019-01-01','2021-01-01','2023-01-01','2025-01-01','2026-08-01')),labels=c('2017','2019','2021','2023','2025','Aug 2026'),expand=expansion(mult=c(.015,.12)))+
 scale_y_continuous(name=NULL,limits=c(0,10000),breaks=seq(0,8000,2000),labels=comma,expand=c(0,0))+
 base+
 theme(axis.text=element_text(size=11.5),axis.title.y=element_blank(),
 plot.title=element_text(family=regular_alias,size=11.5,colour=support,face='plain',margin=margin(b=8)),plot.title.position='panel')
if (!exists('render_target') || render_target != 'presidential-term-index') frame(timeline,'Southern border encounters surged and then fell during Biden\u2019s term; the decline continued under Trump',
 'Daily encounters, averaged by month \u00b7 Jan 2017\u2013Aug 2026',
 'monthly-timeline',7.5,7.5,dpi=400,title_size=22.5,subtitle_size=14.3,footer_size=10.2,
 source_text='U.S. Customs and Border Protection \u00b7 Retrieved Oct 2026.',
 note='Southwest Border Patrol only; excludes encounters at official ports of entry. Encounters count events, not unique people. Includes Title 42 expulsions (Mar 2020\u2013May 2023). Recent totals include interior apprehensions; whether earlier totals included these consistently is unconfirmed.')
