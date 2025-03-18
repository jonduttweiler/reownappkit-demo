import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:test_appkit/constants.dart';

class CryptoController extends ChangeNotifier {
  late ReownAppKit appKit;
  late ReownAppKitModal _appKitModal;
  ReownAppKitModal get appKitModal => _appKitModal;
  bool _modalInitialized = false;
  String? connectedAddress;

  final Set<String> includedWalletIds = {
    'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
    'd01c7758d741b363e637a817a09bcf579feae4db9f5bb16f599fdd1f66e2f974', // Valora
    'fd20dc426fb37566d803205b19bbc1d4096b248ac04548e3cfb6b3a38bd033aa', // Coinbase Wallet
    '4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0', // Trust
  };

  // final Map<String, RequiredNamespace> requiredNamespaces = {
  //   'eip155': RequiredNamespace(
  //     chains: environment == Environment.production
  //         ? ["eip155:42220"]
  //         : ["eip155:44787"],
  //     methods: [
  //       'personal_sign'
  //           'eth_signTypedData_v4'
  //           'eth_sendTransaction'
  //           'eth_requestAccounts'
  //           'eth_signTypedData_v3'
  //           'eth_signTypedData'
  //           'eth_signTransaction'
  //           'wallet_watchAsset',
  //     ],
  //     events: ["chainChanged", "accountsChanged"],
  //   ),
  // };

  CryptoController() {
    initialize();
  }

  Future<void> initialize() async {
    appKit = await ReownAppKit.createInstance(
      projectId: PROJECT_ID,
      logLevel: LogLevel.all,
      metadata: const PairingMetadata(
        name: 'Forest Maker App',
        description: 'ForestMaker',
        url: 'https://forestmaker.org',
        icons: ['https://explorer.forestmaker.org/logo.png'],
        redirect: Redirect(
          native: 'flutterdapp://',
          universal: 'https://www.walletconnect.com',
        ),
      ),
    );

    ReownAppKitModalNetworks.removeSupportedNetworks('solana');
    ReownAppKitModalNetworks.removeSupportedNetworks('eip155');
    ReownAppKitModalNetworks.removeTestNetworks();
    ReownAppKitModalNetworks.addSupportedNetworks('eip155', [celoMainnet]);
    if (environment == Environment.testing) {
      ReownAppKitModalNetworks.addSupportedNetworks('eip155', [celoAlfajores]);
    }
  }

  Future<ReownAppKitModal> initializeModal(BuildContext context) async {
    if (_modalInitialized) {
      return _appKitModal;
    }

    final evmChains = ReownAppKitModalNetworks.getAllSupportedNetworks(
      namespace: 'eip155',
    );
    Map<String, RequiredNamespace>? namespaces = {};
    if (evmChains.isNotEmpty) {
      namespaces['eip155'] = RequiredNamespace(
        chains: evmChains.map((c) => c.chainId).toList(),
        methods: NetworkUtils.defaultNetworkMethods['eip155']!,
        events: NetworkUtils.defaultNetworkEvents['eip155']!,
      );
    }

    _appKitModal = ReownAppKitModal(
      context: context,
      appKit: appKit,
      includedWalletIds: includedWalletIds,
      /* requiredNamespaces: requiredNamespaces, */
      optionalNamespaces: namespaces,
    );

    await _appKitModal.init();

    _modalInitialized = true;
    print("Web3 app and service initialized with namespaces $namespaces");
    return _appKitModal;
  }

  void _onConnection(ModalConnect? event) {
    if (event?.session.getAddress("eip155") != null) {
      connectedAddress = event!.session.getAddress("eip155")!;
      appKitModal.onModalConnect.unsubscribe(_onConnection);

      // upon connection we will check if the requested chain(s) were approved by the wallet
      // Metamask will approve every added chain in the wallet, therefor if a chain is not added in the wallet it will not be approved
      // we check that situation and, in case is not approved (added) we trigger it to be added.
      // this is how Metamask works, we can't do much on our side.
      final approvedChains = _appKitModal.session!.getApprovedChains(
        namespace: 'eip155',
      );
      final isProduction = environment == Environment.production;
      final workingChain = isProduction ? celoMainnet : celoAlfajores;
      if (!approvedChains!.contains(workingChain.chainId)) {
        // This will try to add the chain in the wallet
        // wallet_addEthereumChain has to be added in the namespaces
        // which is added in line 94 with NetworkUtils.defaultNetworkMethods['eip155']!
        _appKitModal.selectChain(workingChain, switchChain: true);
      } else {
        _appKitModal.selectChain(workingChain);
      }
      notifyListeners();
    }
  }

  connect(BuildContext context) async {
    if (!_modalInitialized) {
      await initializeModal(context);
    }

    appKitModal.onModalConnect.subscribe(_onConnection);
    await appKitModal.openModalView();
  }
}
