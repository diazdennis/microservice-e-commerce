# E-Commerce Microservices

A complete e-commerce system built with microservices architecture, featuring product catalog, shopping cart, checkout, and email notifications.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS EC2 t2.micro (Free Tier)             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  Docker Compose                      │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐       │   │
│  │  │  Catalog  │  │ Checkout  │  │   Email   │       │   │
│  │  │  Service  │  │  Service  │  │  Service  │       │   │
│  │  │ (Laravel) │  │ (Laravel) │  │ (Laravel) │       │   │
│  │  │   :80     │  │   :80     │  │   :80     │       │   │
│  │  └───────────┘  └───────────┘  └───────────┘       │   │
│  │       │              │             │               │   │
│  │  ┌────┴──────────────┴─────────────┴────┐          │   │
│  │  │         MySQL Container :3306        │          │   │
│  │  └──────────────────────────────────────┘          │   │
│  │  ┌──────────────────────────────────────┐          │   │
│  │  │     Vue.js Frontend (Nginx) :80      │          │   │
│  │  └──────────────────────────────────────┘          │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │     AWS SES     │
                    │  (Free from EC2)│
                    └─────────────────┘
```

## 🚀 Features

### Catalog Service
- ✅ Product listing with filtering (category, price, search)
- ✅ Product details view
- ✅ Pagination support
- ✅ 15 sample products across 5 categories

### Checkout Service
- ✅ Shopping cart functionality
- ✅ Stock validation before orders
- ✅ Order processing with email integration
- ✅ Guest checkout (no user accounts required)

### Email Service
- ✅ Order confirmation emails
- ✅ Email logging and status tracking
- ✅ Mailtrap (local development) + AWS SES (production)

### Frontend (Vue.js)
- ✅ Responsive product catalog
- ✅ Shopping cart with localStorage persistence
- ✅ Checkout flow with email collection
- ✅ Order confirmation page
- ✅ Mobile-friendly design with Tailwind CSS

## 🛠️ Tech Stack

- **Backend**: PHP 8.1, Laravel 10
- **Frontend**: Vue.js 3, Vite, Tailwind CSS, Pinia
- **Database**: MySQL 8.0
- **Infrastructure**: Docker, Docker Compose, Nginx
- **Cloud**: AWS EC2 (Free Tier), CloudFormation, SES
- **Email**: Mailtrap (dev) + AWS SES (prod)

## 📋 Prerequisites

### Local Development
- **PHP 8.1+** with extensions: `pdo_mysql`, `mbstring`, `xml`, `zip`
- **Composer** (PHP dependency manager)
- **MySQL 8.0** (or XAMPP/WAMP/MAMP)
- **Node.js 18+** and **npm**
- **Mailtrap Account** (free tier for email testing)

### AWS Deployment
- **AWS Account** with Free Tier access
- **EC2 Key Pair** for SSH access
- **AWS CLI** configured (optional)

## 🚀 Quick Start

### Option A: Local Development (No Docker)

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd e-commerce-microservices
   ```

2. **Setup databases**
   ```sql
   CREATE DATABASE catalog_db;
   CREATE DATABASE checkout_db;
   CREATE DATABASE email_db;
   ```

3. **Configure environment variables**
   - Copy `.env.example` files in each service directory
   - Update database credentials and Mailtrap credentials

4. **Start services**
   ```bash
   # Terminal 1 - Catalog Service
   cd services/catalog && composer install && php artisan migrate --seed && php artisan serve --port=8001

   # Terminal 2 - Checkout Service
   cd services/checkout && composer install && php artisan migrate && php artisan serve --port=8002

   # Terminal 3 - Email Service
   cd services/email && composer install && php artisan migrate && php artisan serve --port=8003

   # Terminal 4 - Frontend
   cd frontend && npm install && npm run dev
   ```

5. **Access the application**
   - Frontend: http://localhost:5173
   - APIs: http://localhost:8001/api (catalog), http://localhost:8002/api (checkout), http://localhost:8003/api (email)

### Option B: Docker Development

1. **Clone and setup**
   ```bash
   git clone <your-repo-url>
   cd microservice-ecommerce
   ```

2. **Configure Mailtrap**
   - Add your Mailtrap credentials to `.env` file
   ```bash
   echo "MAILTRAP_USERNAME=your_mailtrap_username" > .env
   echo "MAILTRAP_PASSWORD=your_mailtrap_password" >> .env
   ```

3. **Build the frontend**
   ```bash
   cd frontend
   npm install
   npm run build
   cd ..
   ```

4. **Start all services**
   ```bash
   docker-compose up --build
   ```

5. **Run migrations (first time only)**
   ```bash
   # Wait for containers to be ready, then run:
   docker-compose exec -T catalog php artisan migrate --seed
   docker-compose exec -T checkout php artisan migrate
   docker-compose exec -T email php artisan migrate
   ```

6. **Access the application**
   - Frontend: http://localhost
   - All APIs are proxied through Nginx

## ☁️ AWS Deployment

### Prerequisites
1. **Create Mailtrap account** and get SMTP credentials
2. **Create EC2 Key Pair** in AWS Console
3. **Update repository URL** in CloudFormation template

### Deploy to AWS

1. **Deploy infrastructure**
   ```bash
   aws cloudformation create-stack \
     --stack-name ecommerce \
     --template-body file://infrastructure/cloudformation.yml \
     --parameters ParameterKey=KeyName,ParameterValue=your-key-pair-name \
     --capabilities CAPABILITY_IAM
   ```

2. **Get public IP**
   ```bash
   aws cloudformation describe-stacks --stack-name ecommerce --query 'Stacks[0].Outputs'
   ```

3. **Access your site**
   - Visit the public IP from the CloudFormation outputs
   - The application will be running automatically

### Post-Deployment Updates

To deploy code changes after initial setup:

```bash
# SSH into your EC2 instance
ssh -i your-key.pem ec2-user@<public-ip>

# Navigate to project and pull latest changes
cd /home/ec2-user/e-commerce-microservices
git pull origin main

# Rebuild and restart containers
docker-compose down
docker-compose up -d --build

# Run migrations if needed
docker-compose exec -T catalog php artisan migrate
docker-compose exec -T checkout php artisan migrate
docker-compose exec -T email php artisan migrate
```

## 📧 Email Configuration

### Local Development (Mailtrap)
1. Sign up at [mailtrap.io](https://mailtrap.io)
2. Create an inbox for testing
3. Get SMTP credentials from inbox settings
4. Add SMTP credentials to environment variables

### Production (AWS SES)
- Automatically configured via CloudFormation
- IAM role allows EC2 to send emails
- 62,000 emails/month free from EC2

## 🧪 Testing

### Manual Testing Checklist

1. **Product Catalog**
   - [ ] Browse product list
   - [ ] Filter by category
   - [ ] Search products
   - [ ] Sort by price/name
   - [ ] Pagination works
   - [ ] View product details

2. **Shopping Cart**
   - [ ] Add products to cart
   - [ ] Update quantities
   - [ ] Remove items
   - [ ] Cart persists in localStorage
   - [ ] Cart shows correct totals

3. **Checkout Process**
   - [ ] Enter email address
   - [ ] Review order summary
   - [ ] Submit order successfully
   - [ ] Stock validation works

4. **Email Notifications**
   - [ ] Order confirmation email sent
   - [ ] Email contains correct order details
   - [ ] Email logs recorded in database

5. **User Experience**
   - [ ] Responsive design on mobile
   - [ ] Loading states work
   - [ ] Error messages displayed
   - [ ] Navigation works correctly

### API Testing

```bash
# Test product endpoints
curl http://localhost:8001/api/products
curl http://localhost:8001/api/products/1
curl http://localhost:8001/api/categories

# Test order creation
curl -X POST http://localhost:8002/api/orders \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","items":[{"product_id":1,"quantity":2}]}'
```

## 🏛️ Architecture Decisions

### User Tracking: Guest Checkout

**Why Guest Checkout?**
- ✅ **Demo/MVP scope**: Faster to build and deploy
- ✅ **Free tier compliant**: No additional AWS resources needed
- ✅ **Simple UX**: No registration/login friction
- ✅ **Privacy focused**: No user data storage concerns

**Alternative Approaches:**
- **Full Authentication**: User accounts with order history (requires auth service)
- **Hybrid**: Guest checkout with optional account creation

### Database Architecture

**Separate databases per service** (microservices best practice):
- `catalog_db`: Products and categories
- `checkout_db`: Orders and order items
- `email_db`: Email logs

**Benefits:**
- Service isolation
- Independent scaling
- Easier maintenance
- Clear data ownership

### Email Strategy

**Development**: Mailtrap (free tier, email testing)
**Production**: AWS SES (62K emails/month free from EC2)

## 🔧 Development Scripts

### Windows (start-local.ps1)

**Note:** If you encounter a PowerShell execution policy error, run one of these commands first:

```powershell
# Option 1: Run with bypass (recommended for this session only)
powershell -ExecutionPolicy Bypass -File .\start-local.ps1

# Option 2: Set execution policy for current user (persistent)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Option 3: Run the script directly with bypass
.\start-local.ps1 -ExecutionPolicy Bypass
```

Then run the script:
```powershell
# Run all services locally
.\start-local.ps1
```

### Linux/Mac
```bash
# Make script executable (first time only)
chmod +x start-local.sh

# Run all services locally
./start-local.sh
```

## 📊 Free Tier Compliance

All resources fit within AWS Free Tier limits:

| Service | Free Tier Limit | Usage |
|---------|----------------|--------|
| EC2 t2.micro | 750 hrs/month | ~720 hrs |
| EBS Storage | 30 GB | ~8 GB |
| SES Emails | 62K/month (from EC2) | <100 |
| Data Transfer | 100 GB/month | <1 GB |

**Total estimated cost**: $0/month

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

**Port conflicts**
- Change ports in docker-compose.yml or artisan serve commands

**Database connection errors**
- Verify MySQL credentials in .env files
- Ensure databases are created

**Email not sending**
- Check Mailtrap SMTP credentials (username and password from inbox settings)
- Verify Mailtrap inbox settings
- Ensure `MAIL_ENCRYPTION=null` for Mailtrap (port 2525 doesn't use TLS)
- Check email service logs: `docker-compose logs email` or `services/email/storage/logs/laravel.log`

**Permission errors**
- Run `chmod +x start-local.sh` on Linux/Mac
- Use administrator privileges on Windows

### Logs

**Laravel logs**: `services/*/storage/logs/laravel.log`
**Docker logs**: `docker-compose logs [service-name]`
**Nginx logs**: `docker-compose logs frontend`

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review the logs
3. Create an issue in the repository

---

**Built with ❤️ using PHP, Laravel, Vue.js, and AWS**
