# 🎭 BDD + Actor Scenario Principles

## The Fundamental Breakthrough

Traditional requirements engineering treats technical components as static entities. Our approach treats **everything as actors in scenarios** - humans, systems, and interfaces all participate in behavioral narratives that can be understood by everyone and validated through testing.

## Core Principle: The Actor Trinity

### 🏢 Business Actors (B_S)
**Definition**: Human stakeholders who drive business value creation
**Examples**: Customers, Sales Teams, Support Staff, Administrators
**Scenarios**: Complete business workflows from initiation to value delivery
**Validation**: Business acceptance tests, stakeholder approval

```gherkin
Scenario: B_S001_US001 Customer Places Order
  Given I am a Customer with a valid account
  When I select products and proceed to checkout  
  Then I should complete my purchase successfully
  And I should receive order confirmation
  And the Sales Team should be notified of new order
```

### 🎨 UX Actors (U_S)  
**Definition**: Interface elements and user interaction patterns
**Examples**: Mobile Users, Desktop Users, Screen Readers, Touch Interfaces
**Scenarios**: User experience journeys through designed interfaces
**Validation**: UI automation tests, accessibility compliance, usability testing

```gherkin
Scenario: U_S001_UF001 Mobile Checkout Experience  
  Given I am using a mobile device
  When I navigate through the checkout process
  Then each step should be touch-optimized
  And I should complete checkout in under 3 taps
  And the interface should provide clear feedback
```

### ⚙️ Technical Actors (T_S)
**Definition**: System components that interact to deliver functionality  
**Examples**: APIs, Databases, External Services, Background Workers
**Scenarios**: System interactions and technical behavior validation
**Validation**: Integration tests, API contract tests, component behavior tests

```gherkin
Scenario: T_S001_TC001 Order Processing Pipeline
  Given the Order API receives a valid order request
  When the API validates the order with the Inventory Service
  Then the Payment Service should process the payment
  And the Database should store the order record
  And the Email Service should send confirmation
```

## The Power of Parallel Scenarios

Every business scenario has corresponding technical and UX scenarios that execute in parallel:

```
B_S001: Customer Order Fulfillment
├── U_S001: Mobile Order Experience (parallel)
└── T_S001: Order Processing Systems (parallel)

Success Criteria: All three scenarios must pass
```

This ensures:
- **Business value** is clearly defined
- **User experience** supports the business goal  
- **Technical implementation** enables both

## Actor Relationship Patterns

### 1. **Actor Inheritance**
Base scenarios define common behaviors that variants inherit:

```
B_S001: Standard Customer Order (base)
├── B_S002: VIP Customer Order (inherits 80% from B_S001)
└── B_S003: Bulk Customer Order (inherits 70% from B_S001)
```

### 2. **Actor Dependencies**
Technical actors form dependency chains:

```
T_S001: User Authentication
├── Depends on: T_F001 (Auth Service)  
├── Depends on: T_F002 (Database)
└── Depends on: T_F007 (Email Service)
```

### 3. **Actor Communication**
Actors interact through well-defined interfaces:

```gherkin
Scenario: Cross-Actor Communication
  When Business Actor (Customer) submits order
  Then Technical Actor (Order API) validates request
  And Technical Actor (Database) stores order
  And UX Actor (Mobile Interface) shows confirmation
```

## BDD Integration Patterns

### Given-When-Then Structure
- **Given**: Actor states and preconditions
- **When**: Actor interactions and triggers  
- **Then**: Expected outcomes and behaviors

### Scenario Composition
- **Feature**: Collection of related scenarios
- **Background**: Common setup for all scenarios
- **Scenario Outline**: Template scenarios with examples

### Step Definitions
Each scenario step maps to executable code:

```python
@given('I am a Customer with a valid account')
def customer_with_account(context):
    context.customer = create_test_customer()
    context.account = create_valid_account(context.customer)

@when('I select products and proceed to checkout')
def proceed_to_checkout(context):
    context.cart = add_products_to_cart(context.customer)
    context.checkout_result = initiate_checkout(context.cart)

@then('I should complete my purchase successfully')
def verify_purchase_completion(context):
    assert context.checkout_result.status == 'completed'
    assert context.checkout_result.order_id is not None
```

## Component Hierarchy Rules

### Naming Convention
```
Domain_Type_Scenario_Component_SubComponent

B_S001_US001_USS001  # Business Scenario 1, User Story 1, User Story Step 1
T_S001_TC001_API001  # Technical Scenario 1, Technical Component 1, API 1  
U_S001_UF001_SC001   # UX Scenario 1, User Flow 1, Screen Component 1
```

### Relationship Rules
- **Parent-Child**: Every component has clear lineage
- **Sibling**: Related components at the same level  
- **Cross-Reference**: Components can reference others across domains

### Foundational Components
```
T_F001-015: Platform-wide technical components
U_F001-010: Shared UX/UI components  
B_F001-005: Common business patterns
```

## Validation Principles

### Multi-Level Testing
Each scenario type requires appropriate validation:

- **B_S**: Stakeholder acceptance, business value metrics
- **U_S**: User experience testing, accessibility compliance
- **T_S**: Technical integration, performance validation

### Living Documentation
Scenarios serve as:
- **Requirements specification** for development
- **Test cases** for validation
- **Documentation** for maintenance
- **Communication tool** for stakeholders

### Continuous Validation
- **Code changes** trigger scenario re-execution
- **Failed scenarios** prevent deployment
- **Scenario changes** require stakeholder approval
- **Cross-references** maintain consistency

## Implementation Success Patterns

### Start Small, Scale Gradually
1. **Pilot Scenario**: Implement one complete B_S/T_S/U_S trio
2. **Expand Systematically**: Add scenarios incrementally  
3. **Extract Patterns**: Identify reusable components
4. **Build Templates**: Create scenario templates for future use

### Actor-First Design
1. **Identify Actors**: Who/what participates in the scenario
2. **Define Interactions**: How actors communicate
3. **Specify Outcomes**: What success looks like
4. **Create Tests**: Make scenarios executable

### GitHub-Native Implementation
1. **Issues as Scenarios**: Each scenario is a GitHub issue
2. **Sub-Issues as Steps**: Detailed steps as child issues
3. **Projects for Management**: Actor-based views and filtering
4. **Actions for Automation**: Continuous scenario validation

## Anti-Patterns to Avoid

### ❌ **Implementation-First Scenarios**
Don't start with technical details. Start with business value and work inward.

### ❌ **Single-Domain Thinking**
Don't create business scenarios without corresponding technical and UX scenarios.

### ❌ **Static Documentation**
Don't let scenarios become stale. Make them executable and continuously validated.

### ❌ **Actor Confusion**
Don't mix different types of actors in the same scenario. Keep business, UX, and technical actors in their respective domains.

### ❌ **Missing Cross-References**
Don't create isolated scenarios. Ensure proper relationships and dependencies.

## Advanced Concepts

### Scenario State Machines
Complex workflows can be modeled as actor state transitions:

```gherkin
Scenario: Order State Progression
  Given an Order exists in "pending" state
  When Payment Actor processes payment successfully
  Then Order should transition to "confirmed" state
  And Fulfillment Actor should be notified
  And Customer Actor should receive confirmation
```

### Actor Versioning
Handle component evolution through versioned scenarios:

```
T_S001_v1.0: Basic authentication
T_S001_v2.0: OAuth integration (breaking change)
T_S001_v2.1: Multi-factor authentication (enhancement)
```

### Cross-Project Patterns
Reusable scenario templates across projects:

```
Authentication_Pattern: B_S/T_S/U_S trilogy for user login
Payment_Pattern: B_S/T_S/U_S trilogy for payment processing
Notification_Pattern: B_S/T_S/U_S trilogy for user notifications
```

---

**Next**: Proceed to `scenario-hierarchy.md` to understand how to structure complex scenario relationships.