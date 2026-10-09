import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class QuotationCard extends StatelessWidget {
  final String customerName;
  final String customerPhone;
  final String customerLocation;
  final String propertyType;
  final double kw;
  final int plateCount;
  final double platePrice;
  final double totalPlatesCost;
  final double installCost;
  final double inverterWiringCost;
  final double totalSystemCost;
  final double subsidy;
  final double netPayable;
  final double monthlySavings;
  final double annualSavings;
  final String paybackYears;
  final double profit25Years;
  final double? loanAmount;
  final double? emiAmount;
  final int? loanYears;
  final double? interestRate;
  final double? downPayment;
  final DateTime generatedAt;

  const QuotationCard({
    super.key,
    required this.customerName,
    required this.customerPhone,
    required this.customerLocation,
    required this.propertyType,
    required this.kw,
    required this.plateCount,
    required this.platePrice,
    required this.totalPlatesCost,
    required this.installCost,
    required this.inverterWiringCost,
    required this.totalSystemCost,
    required this.subsidy,
    required this.netPayable,
    required this.monthlySavings,
    required this.annualSavings,
    required this.paybackYears,
    required this.profit25Years,
    this.loanAmount,
    this.emiAmount,
    this.loanYears,
    this.interestRate,
    this.downPayment,
    required this.generatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final numFormat = NumberFormat('#,##,###', 'en_IN');
    final hasLoan = (loanAmount != null && loanAmount! > 0 && emiAmount != null && emiAmount! > 0);

    return Container(
      width: 440,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sun,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. BRAND HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 38,
                      width: 38,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SUNWARD SOLAR',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'OFFICIAL ROOFTOP SOLAR ESTIMATE',
                        style: TextStyle(
                          color: AppColors.ink.withValues(alpha: 0.75),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${kw.toStringAsFixed(1)} kW ON-GRID',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. CUSTOMER DETAILS STRIP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: AppColors.ink),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Client: ${customerName.isEmpty ? "Valued Customer" : customerName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: AppColors.ink),
                        const SizedBox(width: 4),
                        Text(
                          customerPhone.isEmpty ? 'N/A' : customerPhone,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.ink),
                        const SizedBox(width: 4),
                        Text(
                          customerLocation.isEmpty ? 'Direct Consultation' : customerLocation,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.ink),
                        ),
                      ],
                    ),
                    Text(
                      '$propertyType • ${DateFormat('dd MMM yyyy').format(generatedAt)}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. MAIN HERO NUMBERS (Price You Pay, Yearly Savings, 25-Yr Profit)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildHeroStat(
                    'Final Payable',
                    currency.format(netPayable),
                    'After Govt Subsidy',
                    isHighlight: true,
                  ),
                ),
                Container(width: 1, height: 42, color: AppColors.ink.withValues(alpha: 0.2)),
                Expanded(
                  child: _buildHeroStat(
                    'Yearly Savings',
                    currency.format(annualSavings),
                    '₹${numFormat.format(monthlySavings)} / mo',
                  ),
                ),
                Container(width: 1, height: 42, color: AppColors.ink.withValues(alpha: 0.2)),
                Expanded(
                  child: _buildHeroStat(
                    '25-Yr Net Profit',
                    currency.format(profit25Years > 0 ? profit25Years : 0),
                    '$paybackYears Yrs Payback',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. SYSTEM SPECIFICATIONS BOX
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt, size: 15, color: AppColors.ink),
                    SizedBox(width: 4),
                    Text(
                      'SYSTEM SPECIFICATIONS & GENERATION',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpecTile('Solar Plant Size', '${kw.toStringAsFixed(1)} kW On-Grid'),
                    _buildSpecTile('Solar Plates', '$plateCount Plates (540W Mono PERC)'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpecTile('Daily Generation', '~${(kw * 4).round()} Units / Day'),
                    _buildSpecTile('Monthly Generation', '~${(kw * 120).round()} Units / Month'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpecTile('Required Roof Area', '~${(kw * 100).round()} Sq. Ft.'),
                    _buildSpecTile('Inverter Tech', 'Grid-Tie High-Efficiency'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 5. ITEMIZED COST BREAKDOWN (HISAAB)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PAISA KAHAN LAGEGA (COST BREAKDOWN)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                _buildPriceRow('Solar Plates ($plateCount × ₹${platePrice.round()})', currency.format(totalPlatesCost)),
                _buildPriceRow('Mounting Structure & Civil Fitting', currency.format(installCost)),
                _buildPriceRow('Inverter, AC/DC Wiring & Protection', currency.format(inverterWiringCost)),
                const Divider(height: 12, thickness: 1, color: AppColors.ink),
                _buildPriceRow('Total System Cost', currency.format(totalSystemCost), isBold: true),
                _buildPriceRow(
                  'Govt Subsidy Discount (PM Surya Ghar)',
                  subsidy > 0 ? '-${currency.format(subsidy)}' : '₹0 (Commercial/No Subsidy)',
                  isGreen: true,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Net Amount To Pay:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink),
                    ),
                    Text(
                      currency.format(netPayable),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 6. BANK LOAN & EMI (KIST HISAAB) (If loan is selected)
          if (hasLoan) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance, size: 14, color: AppColors.ink),
                          SizedBox(width: 4),
                          Text(
                            'BANK LOAN & EASY EMI (किश्त हिसाब)',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.ink),
                          ),
                        ],
                      ),
                      Text(
                        '$loanYears Yrs @ ${interestRate?.toStringAsFixed(1) ?? "8.5"}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildPriceRow('Sanctioned Loan', currency.format(loanAmount)),
                  _buildPriceRow('Monthly EMI (किश्त)', '${currency.format(emiAmount)} / month'),
                  if (downPayment != null) _buildPriceRow('Down Payment', currency.format(downPayment!)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      monthlySavings >= (emiAmount ?? 0)
                          ? '★ Electricity savings (${currency.format(monthlySavings)}/mo) fully covers your EMI!'
                          : '★ Electricity savings (${currency.format(monthlySavings)}/mo) offsets your EMI!',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),

          // 7. TRUST SEALS & WARRANTIES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrustPill('25-Yr Panel Warranty'),
              _buildTrustPill('5-Yr Inverter Guarantee'),
              _buildTrustPill('MNRE Approved'),
            ],
          ),
          const SizedBox(height: 10),

          // 8. HELPLINE & FOOTER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.support_agent, size: 14, color: AppColors.ink),
                    SizedBox(width: 4),
                    Text(
                      'Sunward Helpline: +91 9731001477',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.ink),
                    ),
                  ],
                ),
                Text(
                  'Book Free Roof Survey',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.ink.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String title, String value, String subtitle, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.ink.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 17 : 14,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.teal : AppColors.ink.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9, color: AppColors.ink.withValues(alpha: 0.65), fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: isGreen ? const Color(0xFF0F5132) : AppColors.ink,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isBold || isGreen ? FontWeight.w900 : FontWeight.w600,
              color: isGreen ? const Color(0xFF0F5132) : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustPill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '✓ $title',
        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.ink),
      ),
    );
  }
}
