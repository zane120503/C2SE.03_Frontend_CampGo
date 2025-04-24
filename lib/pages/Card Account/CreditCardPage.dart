import 'package:CampGo/models/card_model.dart';
import 'package:CampGo/pages/Card%20Account/widgets/AddCreditCardPage.dart';
import 'package:CampGo/pages/Card%20Account/widgets/UpdateCreditCardPage.dart';
import 'package:CampGo/services/data_service.dart';
import 'package:CampGo/services/api_service.dart';
import 'package:flutter/material.dart';

class CreditCardPage extends StatefulWidget {
  final Function(CardModel)? onCardSelected;
  final bool isSelectionMode;

  const CreditCardPage({
    Key? key, 
    this.onCardSelected,
    this.isSelectionMode = false,
  }) : super(key: key);

  @override
  _CreditCardPageState createState() => _CreditCardPageState();
}

class _CreditCardPageState extends State<CreditCardPage> {
  final DataService _dataService = DataService();
  final APIService _apiService = APIService();
  List<CardModel> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final apiService = APIService();
      final response = await apiService.getAllCards();
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> cardsData = response['data'];
        setState(() {
          _cards = cardsData.map((card) => CardModel(
            id: card['_id'] ?? '',
            userId: card['user_id'] ?? '',
            cardNumber: card['card_number'] ?? '',
            cardHolderName: card['card_name'] ?? '',
            cardType: card['card_type'] ?? 'VISA',
            lastFourDigits: card['card_number']?.substring(card['card_number'].length - 4) ?? '',
            expiryMonth: card['card_exp_month']?.toString() ?? '',
            expiryYear: card['card_exp_year']?.toString() ?? '',
            cvv: card['card_cvc'] ?? '',
            isDefault: card['is_default'] ?? false,
            createdAt: card['createdAt'] != null ? DateTime.parse(card['createdAt']) : null,
            updatedAt: card['updatedAt'] != null ? DateTime.parse(card['updatedAt']) : null,
            v: card['__v'] ?? 0,
          )).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load cards',
            textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error loading cards: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCard(String cardId) async {
    try {
      final success = await _dataService.deleteCard(cardId);
      if (success) {
        setState(() {
          _cards.removeWhere((card) => card.id == cardId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card deleted successfully',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete card failed',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e',
        textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setDefaultCard(String cardId) async {
    try {
      final success = await _dataService.setDefaultCard(cardId);
      if (success) {
        setState(() {
          _cards = _cards.map((card) => CardModel(
            id: card.id,
            userId: card.userId,
            cardNumber: card.cardNumber,
            cardHolderName: card.cardHolderName,
            cardType: card.cardType,
            lastFourDigits: card.lastFourDigits,
            expiryMonth: card.expiryMonth,
            expiryYear: card.expiryYear,
            cvv: card.cvv,
            isDefault: card.id == cardId,
            createdAt: card.createdAt,
            updatedAt: card.updatedAt,
            v: card.v,
          )).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set default card successfully',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set default card failed',
          textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e',
        textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateCard(CardModel card) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateCreditCardPage(card: card),
      ),
    );

    if (result == true) {
      _loadCards(); // Reload cards list after successful update
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Credit Card',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!widget.isSelectionMode)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddCreditCardPage()),
                );
                if (result == true) {
                  _loadCards();
                }
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFFEDECF2),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.red,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading cards...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: _cards.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.credit_card_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No cards found',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add a new card to start',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              top: 16,
                              left: 16,
                              right: 16,
                            ),
                            itemCount: _cards.length,
                            itemBuilder: (context, index) {
                              final card = _cards[index];
                              return Dismissible(
                                key: Key(card.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Confirm delete'),
                                      content: Text('Are you sure you want to delete this card?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) => _deleteCard(card.id),
                                child: Card(
                                  margin: EdgeInsets.only(bottom: 16),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              card.cardHolderName ?? 'Card Holder',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Container(
                                              width: 40,
                                              height: 25,
                                              decoration: BoxDecoration(
                                                color: Colors.blue[400],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  card.cardType ?? 'VISA',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          '**** **** **** ${card.lastFourDigits}',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Expires: ${card.expiryMonth}/${card.expiryYear}',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (card.isDefault)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: Colors.red,
                                                      size: 16,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Default',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              TextButton.icon(
                                                onPressed: () => _setDefaultCard(card.id),
                                                icon: Icon(Icons.check_circle_outline,
                                                    color: Colors.red),
                                                label: Text(
                                                  'Set default',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: Size(0, 0),
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ),
                                            InkWell(
                                              onTap: () => _updateCard(card),
                                              child: Icon(
                                                Icons.edit,
                                                size: 22,
                                                color: const Color.fromARGB(255, 255, 0, 0),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
