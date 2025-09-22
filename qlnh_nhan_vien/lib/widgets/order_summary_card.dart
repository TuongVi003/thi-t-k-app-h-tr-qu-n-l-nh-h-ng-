import 'package:flutter/material.dart';

// Placeholder widget for order summary
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Order Summary'),
      ),
    );
  }
}