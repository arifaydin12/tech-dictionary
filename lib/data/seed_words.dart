import '../models/word.dart';

/// The built-in starter dictionary that ships with the app.
class SeedWords {
  const SeedWords._();

  static String slug(String term) => term
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  /// All built-in words, in a stable order.
  static final List<Word> all = List.unmodifiable([
    for (final e in _entries)
      Word(
        id: 'builtin-${slug(e.$1)}',
        term: e.$1,
        category: e.$2,
        definition: e.$3,
        isBuiltIn: true,
      ),
  ]);

  // (term, category, definition)
  static const List<(String, String, String)> _entries = [
    // ---------------------------------------------------------- Hardware
    (
      'CPU',
      'Hardware',
      'The central processing unit: the chip that fetches, decodes and executes program instructions. Its speed depends on clock rate, core count and architecture.',
    ),
    (
      'GPU',
      'Hardware',
      'A graphics processing unit, a processor with thousands of small cores designed for highly parallel work such as rendering images and training neural networks.',
    ),
    (
      'RAM',
      'Hardware',
      'Random-access memory: fast, volatile working memory that holds the data and code of running programs. Its contents are lost when power is removed.',
    ),
    (
      'SSD',
      'Hardware',
      'A solid-state drive stores data in flash memory chips with no moving parts, giving much faster access and better shock resistance than a hard disk.',
    ),
    (
      'Motherboard',
      'Hardware',
      'The main circuit board of a computer. It connects the CPU, memory, storage and expansion cards and distributes power and data between them.',
    ),
    (
      'Cache Memory',
      'Hardware',
      'A small, very fast memory close to the CPU that keeps recently or frequently used data so the processor waits less for main memory.',
    ),
    (
      'BIOS',
      'Hardware',
      'Basic Input/Output System: firmware stored on the motherboard that initialises hardware at power-on and then hands control to the bootloader. UEFI is its modern successor.',
    ),
    (
      'USB',
      'Hardware',
      'Universal Serial Bus, a standard for connecting peripherals and transferring data and power over a single cable and connector family.',
    ),
    (
      'Firmware',
      'Hardware',
      'Low-level software stored in non-volatile memory on a device that controls its basic functions, for example in a router, keyboard or SSD controller.',
    ),
    (
      'Bandwidth',
      'Hardware',
      'The maximum amount of data that can be transferred over a connection or bus in a given time, usually measured in bits or bytes per second.',
    ),
    (
      'Peripheral',
      'Hardware',
      'An external device such as a keyboard, mouse, printer or monitor that connects to a computer to provide input, output or storage.',
    ),
    (
      'Thermal Throttling',
      'Hardware',
      'Automatic reduction of a processor\'s clock speed when it gets too hot, which protects the hardware but lowers performance.',
    ),
    (
      'RAID',
      'Hardware',
      'Redundant Array of Independent Disks: a technique that combines several drives into one logical unit to improve speed, fault tolerance or both.',
    ),
    (
      'NPU',
      'Hardware',
      'A neural processing unit, a chip block specialised in the matrix operations used by machine-learning models, common in phones and laptops.',
    ),
    (
      'Bus',
      'Hardware',
      'A communication pathway that transfers data between components inside a computer, such as between the CPU, memory and expansion cards.',
    ),
    // ---------------------------------------------------------- Software
    (
      'Operating System',
      'Software',
      'The core software that manages hardware resources and provides services to applications. Windows, macOS, Linux, Android and iOS are common examples.',
    ),
    (
      'Kernel',
      'Software',
      'The central part of an operating system. It has full access to the hardware and manages memory, processes, devices and system calls.',
    ),
    (
      'Process',
      'Software',
      'A running instance of a program, with its own memory space and system resources, managed and scheduled by the operating system.',
    ),
    (
      'Thread',
      'Software',
      'The smallest unit of execution scheduled by an operating system. Threads of one process share its memory, which makes them lightweight but harder to synchronise.',
    ),
    (
      'Driver',
      'Software',
      'Software that lets the operating system communicate with a hardware device such as a printer or graphics card.',
    ),
    (
      'Virtual Machine',
      'Software',
      'A software emulation of a complete computer that runs its own operating system on top of a hypervisor, isolated from the host.',
    ),
    (
      'Container',
      'Software',
      'A lightweight, isolated package containing an application and its dependencies. Containers share the host kernel, so they start faster than virtual machines.',
    ),
    (
      'Open Source',
      'Software',
      'Software whose source code is publicly available and licensed so that anyone may inspect, modify and redistribute it.',
    ),
    (
      'Compiler',
      'Software',
      'A program that translates source code written in a high-level language into machine code or bytecode before the program is run.',
    ),
    (
      'Interpreter',
      'Software',
      'A program that reads and executes source code directly, statement by statement, instead of compiling it to machine code in advance.',
    ),
    (
      'Version Control',
      'Software',
      'A system that records changes to files over time so that earlier versions can be recovered and several people can collaborate. Git is the most popular example.',
    ),
    (
      'Git',
      'Software',
      'A distributed version control system that tracks changes in a repository using commits, branches and merges.',
    ),
    (
      'Cache',
      'Software',
      'A temporary store of previously fetched or computed data kept so that future requests for it can be served faster.',
    ),
    (
      'Middleware',
      'Software',
      'Software that sits between applications or between an application and the operating system, providing shared services such as messaging, authentication or logging.',
    ),
    (
      'Software Bug',
      'Software',
      'A flaw in a program that causes it to produce incorrect results or behave in unintended ways.',
    ),
    // -------------------------------------------------------- Networking
    (
      'IP Address',
      'Networking',
      'A numerical label assigned to every device on a network that uses the Internet Protocol. It identifies the device and its location in the network.',
    ),
    (
      'DNS',
      'Networking',
      'The Domain Name System translates human-readable domain names such as example.com into the IP addresses computers use to reach each other.',
    ),
    (
      'DHCP',
      'Networking',
      'Dynamic Host Configuration Protocol: a service that automatically assigns IP addresses and other network settings to devices when they join a network.',
    ),
    (
      'Router',
      'Networking',
      'A device that forwards data packets between networks, choosing the path for each packet. A home router connects the local network to the Internet.',
    ),
    (
      'Switch',
      'Networking',
      'A network device that connects devices within one local network and forwards frames only to the port of the intended recipient.',
    ),
    (
      'Firewall',
      'Networking',
      'A system that monitors network traffic and allows or blocks it according to security rules, separating trusted networks from untrusted ones.',
    ),
    (
      'LAN',
      'Networking',
      'A local area network connects computers within a limited area such as a home, office or campus.',
    ),
    (
      'WAN',
      'Networking',
      'A wide area network spans a large geographic area and links smaller networks together. The Internet is the largest WAN.',
    ),
    (
      'TCP',
      'Networking',
      'Transmission Control Protocol: a reliable, connection-oriented transport protocol that delivers data in order and retransmits lost packets.',
    ),
    (
      'UDP',
      'Networking',
      'User Datagram Protocol: a connectionless transport protocol with no delivery guarantee but low overhead, used for streaming, gaming and DNS.',
    ),
    (
      'HTTP',
      'Networking',
      'Hypertext Transfer Protocol, the request-response protocol that web browsers and servers use to exchange pages and data.',
    ),
    (
      'VPN',
      'Networking',
      'A virtual private network creates an encrypted tunnel across a public network so traffic is protected and appears to come from the VPN endpoint.',
    ),
    (
      'Latency',
      'Networking',
      'The delay between sending a request and receiving the first part of the response, usually measured in milliseconds.',
    ),
    (
      'Packet',
      'Networking',
      'A small unit of data sent over a network, made up of a header with addressing information and a payload with the actual content.',
    ),
    (
      'Subnet',
      'Networking',
      'A logical subdivision of an IP network. Subnetting splits a large network into smaller parts to improve organisation, performance and security.',
    ),
    (
      'NAT',
      'Networking',
      'Network Address Translation rewrites IP addresses as packets pass through a router, letting many devices share one public address.',
    ),
    // ---------------------------------------------------------- Security
    (
      'Encryption',
      'Security',
      'Transforming readable data into unreadable ciphertext with an algorithm and a key, so only holders of the correct key can read it.',
    ),
    (
      'Hashing',
      'Security',
      'Mapping data of any size to a fixed-size value with a one-way function. Hashes are used to verify integrity and to store passwords safely.',
    ),
    (
      'Phishing',
      'Security',
      'A social-engineering attack in which a fraudulent message impersonates a trusted party to trick the victim into revealing credentials or installing malware.',
    ),
    (
      'Malware',
      'Security',
      'Malicious software designed to damage systems, steal information or gain unauthorised access, including viruses, worms, trojans and ransomware.',
    ),
    (
      'Ransomware',
      'Security',
      'Malware that encrypts a victim\'s files and demands payment in exchange for the decryption key.',
    ),
    (
      'Two-Factor Authentication',
      'Security',
      'A login method requiring two different proofs of identity, typically a password plus a code from an app or a hardware key.',
    ),
    (
      'Zero-Day',
      'Security',
      'A vulnerability unknown to the software vendor and therefore unpatched, which attackers may exploit before any fix exists.',
    ),
    (
      'SQL Injection',
      'Security',
      'An attack that inserts malicious SQL into an application\'s input so the database runs unintended commands. Parameterised queries prevent it.',
    ),
    (
      'Cross-Site Scripting',
      'Security',
      'XSS: an attack in which malicious script is injected into a web page and runs in other users\' browsers. Output escaping and content security policies mitigate it.',
    ),
    (
      'Public-Key Cryptography',
      'Security',
      'Encryption that uses a key pair: a public key anyone can use to encrypt or verify, and a private key kept secret to decrypt or sign.',
    ),
    (
      'TLS',
      'Security',
      'Transport Layer Security, the protocol that encrypts and authenticates connections, for example the padlock in HTTPS.',
    ),
    (
      'Penetration Testing',
      'Security',
      'An authorised, simulated attack on a system carried out to find and fix security weaknesses before real attackers do.',
    ),
    (
      'Social Engineering',
      'Security',
      'Manipulating people, rather than technology, into disclosing confidential information or performing unsafe actions.',
    ),
    (
      'Principle of Least Privilege',
      'Security',
      'A design rule stating that every user and program should have only the minimum access needed to do its job.',
    ),
    (
      'DDoS',
      'Security',
      'A distributed denial-of-service attack floods a target with traffic from many sources to make a service unavailable to legitimate users.',
    ),
    // ------------------------------------------------------- Programming
    (
      'Algorithm',
      'Programming',
      'A finite, well-defined sequence of steps for solving a problem or performing a computation.',
    ),
    (
      'Variable',
      'Programming',
      'A named storage location in a program that holds a value which can change during execution.',
    ),
    (
      'Function',
      'Programming',
      'A reusable block of code that performs a specific task, optionally takes parameters and may return a value.',
    ),
    (
      'Recursion',
      'Programming',
      'A technique in which a function solves a problem by calling itself on smaller instances until it reaches a base case.',
    ),
    (
      'Object-Oriented Programming',
      'Programming',
      'A paradigm that organises code into objects combining data and behaviour, using ideas such as encapsulation, inheritance and polymorphism.',
    ),
    (
      'Class',
      'Programming',
      'A blueprint that defines the data and behaviour shared by the objects created from it.',
    ),
    (
      'API',
      'Programming',
      'Application Programming Interface: a defined set of functions or endpoints through which one piece of software can use the services of another.',
    ),
    (
      'Big O Notation',
      'Programming',
      'A way of describing how the running time or memory use of an algorithm grows with input size, ignoring constant factors, for example O(n log n).',
    ),
    (
      'Data Structure',
      'Programming',
      'A way of organising data in memory, such as an array, linked list, stack, queue, tree or hash table, so it can be used efficiently.',
    ),
    (
      'Stack',
      'Programming',
      'A last-in, first-out data structure: items are added and removed only at the top. It also names the memory region that holds function calls.',
    ),
    (
      'Queue',
      'Programming',
      'A first-in, first-out data structure in which items are added at the back and removed from the front.',
    ),
    (
      'Hash Table',
      'Programming',
      'A data structure that maps keys to values using a hash function, offering average constant-time lookup, insertion and deletion.',
    ),
    (
      'Debugging',
      'Programming',
      'The process of finding, understanding and fixing defects in a program, often with breakpoints, logging and tests.',
    ),
    (
      'Refactoring',
      'Programming',
      'Restructuring existing code to improve readability and maintainability without changing its external behaviour.',
    ),
    (
      'Unit Test',
      'Programming',
      'An automated test that checks one small piece of code, such as a function, in isolation to confirm it behaves as expected.',
    ),
    (
      'Exception',
      'Programming',
      'An event that interrupts normal program flow when an error occurs. It can be caught and handled by surrounding code.',
    ),
    (
      'Garbage Collection',
      'Programming',
      'Automatic memory management that finds objects a program can no longer reach and frees their memory.',
    ),
    (
      'Asynchronous Programming',
      'Programming',
      'A style in which long-running operations such as network calls run without blocking the program, which continues and handles the result later.',
    ),
    (
      'Design Pattern',
      'Programming',
      'A general, reusable solution to a commonly occurring problem in software design, such as Observer, Factory or Singleton.',
    ),
    // --------------------------------------------------------- Databases
    (
      'Database',
      'Databases',
      'An organised collection of data stored electronically so it can be efficiently queried, updated and managed.',
    ),
    (
      'SQL',
      'Databases',
      'Structured Query Language, the standard language for defining, querying and modifying data in relational databases.',
    ),
    (
      'Relational Database',
      'Databases',
      'A database that stores data in tables of rows and columns and links tables through keys. PostgreSQL and MySQL are examples.',
    ),
    (
      'NoSQL',
      'Databases',
      'A family of non-relational databases, including document, key-value, column and graph stores, built for flexible schemas and horizontal scaling.',
    ),
    (
      'Primary Key',
      'Databases',
      'A column or set of columns whose values uniquely identify each row in a table.',
    ),
    (
      'Foreign Key',
      'Databases',
      'A column that references the primary key of another table, creating a link between rows and enforcing referential integrity.',
    ),
    (
      'Index',
      'Databases',
      'A data structure that speeds up lookups on one or more columns at the cost of extra storage and slower writes.',
    ),
    (
      'Transaction',
      'Databases',
      'A group of database operations treated as a single unit: either all of them succeed and are committed, or none take effect.',
    ),
    (
      'ACID',
      'Databases',
      'The four guarantees of reliable transactions: Atomicity, Consistency, Isolation and Durability.',
    ),
    (
      'Normalisation',
      'Databases',
      'Organising tables to reduce redundancy and avoid update anomalies by splitting data into related tables.',
    ),
    (
      'JOIN',
      'Databases',
      'An SQL operation that combines rows from two or more tables based on a related column.',
    ),
    (
      'Query',
      'Databases',
      'A request to a database to retrieve or change data, usually written in SQL.',
    ),
    (
      'Sharding',
      'Databases',
      'Splitting a large dataset across several database servers, each holding a subset, so storage and load can scale horizontally.',
    ),
    (
      'Data Warehouse',
      'Databases',
      'A central repository that integrates data from many sources and is optimised for analytics and reporting rather than everyday transactions.',
    ),
    (
      'ORM',
      'Databases',
      'Object-Relational Mapping: a technique and library that lets developers work with database rows as objects in their programming language.',
    ),
    // ------------------------------------------------------------- AI/ML
    (
      'Artificial Intelligence',
      'AI/ML',
      'The field of building systems that perform tasks normally requiring human intelligence, such as perception, reasoning, language and decision making.',
    ),
    (
      'Machine Learning',
      'AI/ML',
      'A branch of AI in which algorithms learn patterns from data to make predictions or decisions, instead of following explicitly programmed rules.',
    ),
    (
      'Neural Network',
      'AI/ML',
      'A model made of layers of connected units that transform inputs step by step. Its weights are adjusted during training to reduce error.',
    ),
    (
      'Deep Learning',
      'AI/ML',
      'Machine learning with neural networks that have many layers, which can learn complex features from images, audio and text.',
    ),
    (
      'Supervised Learning',
      'AI/ML',
      'Training a model on labelled examples so it learns to predict the correct output for new inputs.',
    ),
    (
      'Unsupervised Learning',
      'AI/ML',
      'Finding structure, such as clusters or patterns, in data that has no labels.',
    ),
    (
      'Overfitting',
      'AI/ML',
      'When a model learns the training data, including its noise, so well that it performs poorly on new, unseen data.',
    ),
    (
      'Training Data',
      'AI/ML',
      'The set of examples a machine-learning model learns from. Its quality and diversity strongly affect how well the model works.',
    ),
    (
      'Large Language Model',
      'AI/ML',
      'A neural network trained on vast amounts of text to predict the next token, which enables it to generate and summarise language and answer questions.',
    ),
    (
      'Transformer',
      'AI/ML',
      'A neural network architecture built on the attention mechanism, which lets a model weigh the relevance of every part of the input. It underlies most modern language models.',
    ),
    (
      'Reinforcement Learning',
      'AI/ML',
      'A learning method where an agent takes actions in an environment and improves its strategy using rewards and penalties.',
    ),
    (
      'Natural Language Processing',
      'AI/ML',
      'The area of AI concerned with enabling computers to understand, interpret and generate human language.',
    ),
    (
      'Computer Vision',
      'AI/ML',
      'The field that teaches computers to interpret images and video, for tasks such as object detection and face recognition.',
    ),
    (
      'Gradient Descent',
      'AI/ML',
      'An optimisation method that repeatedly adjusts model parameters in the direction that most reduces the loss function.',
    ),
    (
      'Hallucination',
      'AI/ML',
      'When a generative AI model produces fluent but false or unsupported information, presented as if it were fact.',
    ),
    // ------------------------------------------------------------- Cloud
    (
      'Cloud Computing',
      'Cloud',
      'Delivering computing resources such as servers, storage and software over the Internet on demand, usually with pay-as-you-go pricing.',
    ),
    (
      'IaaS',
      'Cloud',
      'Infrastructure as a Service: rented virtual machines, storage and networking, where the customer manages the operating system and everything above it.',
    ),
    (
      'PaaS',
      'Cloud',
      'Platform as a Service: a managed environment in which developers deploy applications without managing the underlying servers.',
    ),
    (
      'SaaS',
      'Cloud',
      'Software as a Service: applications delivered over the Internet, usually through a browser and paid for by subscription.',
    ),
    (
      'Serverless',
      'Cloud',
      'A cloud model in which the provider runs and scales your code on demand and bills per execution, so you do not manage servers.',
    ),
    (
      'Kubernetes',
      'Cloud',
      'An open-source platform that automates the deployment, scaling and management of containerised applications across a cluster of machines.',
    ),
    (
      'Docker',
      'Cloud',
      'A platform for building, shipping and running applications in containers.',
    ),
    (
      'Load Balancer',
      'Cloud',
      'A component that distributes incoming traffic across several servers to improve capacity, availability and reliability.',
    ),
    (
      'CDN',
      'Cloud',
      'A content delivery network caches content on servers around the world so users receive it from a location close to them.',
    ),
    (
      'Auto Scaling',
      'Cloud',
      'Automatically adding or removing computing resources according to demand so performance stays steady and costs stay low.',
    ),
    (
      'Microservices',
      'Cloud',
      'An architecture in which an application is built as a set of small, independently deployable services that communicate over a network.',
    ),
    (
      'DevOps',
      'Cloud',
      'A culture and set of practices that unite development and operations through automation, continuous delivery and monitoring.',
    ),
    (
      'CI/CD',
      'Cloud',
      'Continuous integration and continuous delivery: automatically building, testing and releasing code changes so software can be shipped frequently and safely.',
    ),
    (
      'Infrastructure as Code',
      'Cloud',
      'Managing and provisioning infrastructure through version-controlled configuration files instead of manual setup. Terraform is a well-known tool.',
    ),
    (
      'Object Storage',
      'Cloud',
      'A storage service that keeps data as objects with metadata in flat buckets, suited to large amounts of unstructured data such as images and backups.',
    ),
    // --------------------------------------------------------------- Web
    (
      'HTML',
      'Web',
      'HyperText Markup Language, the standard language that defines the structure and content of web pages using elements.',
    ),
    (
      'CSS',
      'Web',
      'Cascading Style Sheets: the language that controls how HTML elements look, including colour, layout and typography.',
    ),
    (
      'JavaScript',
      'Web',
      'The programming language of the web. It runs in browsers, and on servers with Node.js, to make pages interactive.',
    ),
    (
      'Browser',
      'Web',
      'An application that retrieves, renders and lets users interact with web content, for example Firefox, Chrome, Safari or Edge.',
    ),
    (
      'DOM',
      'Web',
      'The Document Object Model: a tree representation of an HTML page that scripts can read and modify.',
    ),
    (
      'REST',
      'Web',
      'Representational State Transfer, an architectural style for web APIs that uses standard HTTP methods on resources identified by URLs.',
    ),
    (
      'JSON',
      'Web',
      'JavaScript Object Notation, a lightweight text format for exchanging structured data as key-value pairs and arrays.',
    ),
    (
      'Cookie',
      'Web',
      'A small piece of data a website stores in the browser, used to keep users signed in and remember preferences.',
    ),
    (
      'Responsive Design',
      'Web',
      'Building web pages whose layout adapts to the screen size, so they work on phones, tablets and desktops.',
    ),
    (
      'WebSocket',
      'Web',
      'A protocol that keeps a persistent two-way connection between browser and server, enabling real-time features such as chat.',
    ),
    (
      'Progressive Web App',
      'Web',
      'A web application that can be installed, work offline and send notifications, giving it an app-like experience in the browser.',
    ),
    (
      'WebAssembly',
      'Web',
      'A compact binary instruction format that lets code written in languages such as C++ or Rust run in the browser at near-native speed.',
    ),
    (
      'Single-Page Application',
      'Web',
      'A web app that loads one HTML page and updates its content dynamically with JavaScript instead of loading a new page for every action.',
    ),
    (
      'Web Accessibility',
      'Web',
      'Designing sites so people with disabilities can use them, for example with screen readers, keyboard navigation and sufficient colour contrast.',
    ),
    (
      'SEO',
      'Web',
      'Search engine optimisation: improving a website\'s structure and content so that it ranks higher in search results.',
    ),
  ];
}
