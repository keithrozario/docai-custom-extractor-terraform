import os
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors

os.makedirs("samples", exist_ok=True)

invoices_data = [
    {
        "filename": "samples/invoice1_acme_corp.pdf",
        "supplier": "Acme Industrial Solutions",
        "address": "100 Innovation Way, Suite 400\nAustin, TX 78701",
        "invoice_num": "INV-2026-001",
        "date": "2026-03-15",
        "due_date": "2026-04-15",
        "billed_to": "TechStart Inc.\n500 Enterprise Blvd, San Jose, CA 95110",
        "items": [
            ["Industrial Server Rack Mounts", "2", "$350.00", "$700.00"],
            ["High-Speed Fiber Optic Cables", "5", "$40.00", "$200.00"],
            ["On-Site Hardware Installation", "1", "$350.00", "$350.00"]
        ],
        "total": "$1,250.00"
    },
    {
        "filename": "samples/invoice2_apex_logistics.pdf",
        "supplier": "Apex Global Logistics",
        "address": "450 Freight Terminal Rd\nChicago, IL 60666",
        "invoice_num": "APX-88492",
        "date": "2026-04-02",
        "due_date": "2026-05-02",
        "billed_to": "Global Traders Ltd.\n120 Logistics Hub, Seattle, WA 98101",
        "items": [
            ["Air Freight Transit (Standard)", "1", "$2,800.00", "$2,800.00"],
            ["Customs Clearance & Documentation", "1", "$650.00", "$650.00"],
            ["Warehousing Storage Fee (7 Days)", "1", "$390.50", "$390.50"]
        ],
        "total": "$3,840.50"
    },
    {
        "filename": "samples/invoice3_global_supplies.pdf",
        "supplier": "Global Office Supplies Co",
        "address": "789 Commercial Blvd\nAtlanta, GA 30303",
        "invoice_num": "GOS-10492",
        "date": "2026-05-10",
        "due_date": "2026-06-10",
        "billed_to": "Creative Agency Group\n300 Main St, New York, NY 10001",
        "items": [
            ["Ergonomic Executive Office Chairs", "1", "$250.00", "$250.00"],
            ["Premium Recycled Printer Paper (Case)", "3", "$45.25", "$135.75"],
            ["Desk Organizer Trays & Supplies", "2", "$49.75", "$99.50"]
        ],
        "total": "$485.25"
    },
    {
        "filename": "samples/invoice4_nexus_software.pdf",
        "supplier": "Nexus Cloud Systems Inc",
        "address": "250 Tech Park Drive\nBoston, MA 02110",
        "invoice_num": "NXS-99201",
        "date": "2026-06-01",
        "due_date": "2026-07-01",
        "billed_to": "DataWorks LLC\n800 Analytics Way, Denver, CO 80202",
        "items": [
            ["Enterprise Cloud Hosting (Monthly)", "1", "$1,500.00", "$1,500.00"],
            ["24/7 Dedicated Technical Support Plan", "1", "$600.00", "$600.00"]
        ],
        "total": "$2,100.00"
    },
    {
        "filename": "samples/invoice5_summit_consulting.pdf",
        "supplier": "Summit Advisory Group",
        "address": "555 Financial Plaza\nSan Francisco, CA 94104",
        "invoice_num": "SAG-77310",
        "date": "2026-07-22",
        "due_date": "2026-08-22",
        "billed_to": "Venture Partners LLC\n400 Market St, San Francisco, CA 94105",
        "items": [
            ["Cloud Infrastructure Security Audit", "1", "$3,500.00", "$3,500.00"],
            ["SOC 2 Compliance Readiness Review", "1", "$2,000.00", "$2,000.00"]
        ],
        "total": "$5,500.00"
    }
]

styles = getSampleStyleSheet()
title_style = ParagraphStyle(
    'DocTitle',
    parent=styles['Heading1'],
    fontSize=22,
    leading=26,
    textColor=colors.HexColor('#1A365D')
)
header_style = ParagraphStyle(
    'CompanyHeader',
    parent=styles['Normal'],
    fontSize=10,
    leading=14,
    textColor=colors.HexColor('#4A5568')
)
bold_style = ParagraphStyle(
    'BoldText',
    parent=styles['Normal'],
    fontSize=10,
    leading=14,
    fontName='Helvetica-Bold'
)
normal_style = ParagraphStyle(
    'NormalText',
    parent=styles['Normal'],
    fontSize=10,
    leading=14
)

for inv in invoices_data:
    doc = SimpleDocTemplate(
        inv["filename"],
        pagesize=letter,
        rightMargin=36,
        leftMargin=36,
        topMargin=36,
        bottomMargin=36
    )
    elements = []

    # Title & Supplier Header
    elements.append(Paragraph("INVOICE", title_style))
    elements.append(Spacer(1, 10))

    header_data = [
        [
            Paragraph(f"<b>{inv['supplier']}</b><br/>{inv['address'].replace('\n', '<br/>')}", normal_style),
            Paragraph(f"<b>Invoice #:</b> {inv['invoice_num']}<br/><b>Invoice Date:</b> {inv['date']}<br/><b>Due Date:</b> {inv['due_date']}", normal_style)
        ]
    ]
    header_table = Table(header_data, colWidths=[300, 240])
    header_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ]))
    elements.append(header_table)
    elements.append(Spacer(1, 15))
    elements.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor('#CBD5E0'), spaceAfter=15))

    # Billed To
    elements.append(Paragraph(f"<b>Billed To:</b><br/>{inv['billed_to'].replace('\n', '<br/>')}", normal_style))
    elements.append(Spacer(1, 15))

    # Table Items
    table_data = [["Description", "Qty", "Unit Price", "Total"]]
    for item in inv["items"]:
        table_data.append([
            Paragraph(item[0], normal_style),
            Paragraph(item[1], normal_style),
            Paragraph(item[2], normal_style),
            Paragraph(item[3], normal_style)
        ])

    items_table = Table(table_data, colWidths=[280, 50, 105, 105])
    items_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#E2E8F0')),
        ('TEXTCOLOR', (0,0), (-1,0), colors.HexColor('#2D3748')),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E2E8F0')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    elements.append(items_table)
    elements.append(Spacer(1, 15))

    # Total Box
    total_data = [
        ["", "TOTAL AMOUNT:", inv["total"]]
    ]
    total_table = Table(total_data, colWidths=[280, 155, 105])
    total_table.setStyle(TableStyle([
        ('FONTNAME', (1,0), (-1,-1), 'Helvetica-Bold'),
        ('TEXTCOLOR', (1,0), (-1,-1), colors.HexColor('#1A365D')),
        ('ALIGN', (1,0), (-1,-1), 'RIGHT'),
        ('BACKGROUND', (1,0), (-1,-1), colors.HexColor('#EDF2F7')),
        ('TOPPADDING', (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
    ]))
    elements.append(total_table)
    elements.append(Spacer(1, 30))
    elements.append(Paragraph("Thank you for your business!", ParagraphStyle('Thanks', parent=normal_style, fontName='Helvetica-Oblique', textColor=colors.HexColor('#718096'))))

    doc.build(elements)
    print(f"Generated: {inv['filename']}")

print("All 5 invoice PDFs successfully created.")
