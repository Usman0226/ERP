# Fee Management App

A comprehensive Django application for managing student fees, payments, waivers, and discounts in educational institutions.

## Features

- **Fee Structure Management**: Define fee structures for different academic years and grade levels
- **Fee Categories**: Organize fees into categories (Tuition, Library, Sports, etc.)
- **Student Fee Tracking**: Track individual student fee records and balances
- **Payment Management**: Record and track all fee payments with multiple payment methods
- **Fee Waivers**: Apply and manage fee waivers for scholarships and financial aid
- **Fee Discounts**: Apply discounts for early payments, sibling discounts, etc.
- **Receipt Generation**: Generate and manage fee receipts
- **Comprehensive Reporting**: Dashboard with fee summaries and statistics

## Models

### Core Models

1. **FeeCategory**: Fee categories like Tuition, Library, Sports, etc.
2. **FeeStructure**: Fee structures for different academic years and grades
3. **FeeStructureDetail**: Individual fee items within a fee structure
4. **StudentFee**: Individual student fee records
5. **Payment**: Payment records for student fees
6. **FeeWaiver**: Fee waivers for students
7. **FeeDiscount**: Fee discounts for various reasons
8. **FeeReceipt**: Generated fee receipts for payments

### Key Features

- **UUID-based primary keys** for security
- **Automatic timestamps** for audit trails
- **Comprehensive validation** for data integrity
- **Flexible fee structures** supporting multiple frequencies
- **Late fee calculation** with configurable amounts and percentages
- **Multiple payment methods** (Cash, Cheque, Online, etc.)
- **Receipt number generation** with automatic sequencing

## API Endpoints

### Base URL: `/api/v1/fees/`

#### Fee Categories
- `GET/POST /categories/` - List/Create fee categories
- `GET/PUT/DELETE /categories/{id}/` - Retrieve/Update/Delete category
- `GET /categories/active/` - Get active categories only

#### Fee Structures
- `GET/POST /structures/` - List/Create fee structures
- `GET/PUT/DELETE /structures/{id}/` - Retrieve/Update/Delete structure
- `GET /structures/{id}/details/` - Get structure with all details
- `GET /structures/active/` - Get active structures only
- `GET /structures/by_academic_year/?academic_year=2024-2025` - Filter by academic year

#### Fee Structure Details
- `GET/POST /structure-details/` - List/Create structure details
- `GET/PUT/DELETE /structure-details/{id}/` - Retrieve/Update/Delete detail

#### Student Fees
- `GET/POST /student-fees/` - List/Create student fees
- `GET/PUT/DELETE /student-fees/{id}/` - Retrieve/Update/Delete student fee
- `GET /student-fees/overdue/` - Get overdue fees
- `GET /student-fees/by_student/?student_id={id}` - Get fees for specific student
- `GET /student-fees/summary/` - Get fee summary statistics
- `GET /student-fees/student_summary/` - Get fee summary for all students

#### Payments
- `GET/POST /payments/` - List/Create payments
- `GET/PUT/DELETE /payments/{id}/` - Retrieve/Update/Delete payment
- `GET /payments/by_date_range/?start_date=2024-01-01&end_date=2024-12-31` - Filter by date range
- `GET /payments/by_method/?method=CASH` - Filter by payment method
- `POST /payments/{id}/mark_completed/` - Mark payment as completed

#### Fee Waivers
- `GET/POST /waivers/` - List/Create waivers
- `GET/PUT/DELETE /waivers/{id}/` - Retrieve/Update/Delete waiver
- `GET /waivers/active/` - Get active waivers only
- `POST /waivers/{id}/approve/` - Approve a waiver

#### Fee Discounts
- `GET/POST /discounts/` - List/Create discounts
- `GET/PUT/DELETE /discounts/{id}/` - Retrieve/Update/Delete discount
- `GET /discounts/active/` - Get active discounts only
- `GET /discounts/valid/` - Get valid (non-expired) discounts

#### Fee Receipts
- `GET/POST /receipts/` - List/Create receipts
- `GET/PUT/DELETE /receipts/{id}/` - Retrieve/Update/Delete receipt
- `GET /receipts/unprinted/` - Get unprinted receipts
- `POST /receipts/{id}/mark_printed/` - Mark receipt as printed
- `GET /receipts/{id}/download/` - Download receipt (placeholder)

## Usage Examples

### Creating a Fee Structure

```python
# Create fee categories
tuition_category = FeeCategory.objects.create(
    name="Tuition Fee",
    description="Monthly tuition fee",
    display_order=1
)

# Create fee structure
fee_structure = FeeStructure.objects.create(
    name="Grade 10 Fees 2024-2025",
    academic_year="2024-2025",
    grade_level="10",
    description="Complete fee structure for Grade 10"
)

# Add fee details
FeeStructureDetail.objects.create(
    fee_structure=fee_structure,
    fee_category=tuition_category,
    amount=5000.00,
    frequency="MONTHLY",
    is_optional=False
)
```

### Recording a Payment

```python
# Get student fee record
student_fee = StudentFee.objects.get(id=student_fee_id)

# Create payment
payment = Payment.objects.create(
    student_fee=student_fee,
    amount=2500.00,
    payment_method="CASH",
    collected_by=request.user,
    notes="Partial payment for January"
)
```

### Applying a Waiver

```python
# Create fee waiver
waiver = FeeWaiver.objects.create(
    student_fee=student_fee,
    waiver_type="SCHOLARSHIP",
    amount=1000.00,
    percentage=20.00,
    reason="Merit scholarship for academic excellence"
)
```

## Admin Interface

The app includes a comprehensive Django admin interface with:

- **List displays** with relevant information
- **Filters** for easy data navigation
- **Search functionality** across multiple fields
- **Inline editing** for quick updates
- **Custom actions** for bulk operations
- **Optimized queries** with select_related and prefetch_related

## Configuration

### Settings

Add the fees app to your `INSTALLED_APPS`:

```python
INSTALLED_APPS = [
    # ... other apps
    'fees',
]
```

### URLs

Include the fees URLs in your main URL configuration:

```python
urlpatterns = [
    # ... other URLs
    path('api/v1/fees/', include('fees.urls', namespace='fees')),
]
```

## Dependencies

- Django 4.0+
- Django REST Framework 3.12+
- django-filter 22.0+

## Contributing

1. Follow Django coding standards
2. Add tests for new functionality
3. Update documentation for API changes
4. Ensure proper validation and error handling

## License

This app is part of the CampsHub360 project and follows the same licensing terms.
