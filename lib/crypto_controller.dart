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

  final Map<String, RequiredNamespace> requiredNamespaces = {
    'eip155': RequiredNamespace(
      chains: environment == Environment.production ? ["eip155:42220"] : ["eip155:44787"],
      methods: [
        'personal_sign'
            'eth_signTypedData_v4'
            'eth_sendTransaction'
            'eth_requestAccounts'
            'eth_signTypedData_v3'
            'eth_signTypedData'
            'eth_signTransaction'
            'wallet_watchAsset',
      ],
      events: ["chainChanged", "accountsChanged"],
    ),
  };

  CryptoController() {
    initialize();
  }

  Future<void> initialize() async {
    appKit = await ReownAppKit.createInstance(
      projectId: PROJECT_ID,
      metadata: const PairingMetadata(
        name: 'Forest Maker App',
        description: 'ForestMaker',
        url: 'https://forestmaker.org',
        icons: ['https://explorer.forestmaker.org/logo.png'],
        redirect: Redirect(native: 'flutterdapp://', universal: 'https://www.walletconnect.com'),
      ),
    );

    ReownAppKitModalNetworks.removeSupportedNetworks('solana');
    ReownAppKitModalNetworks.removeSupportedNetworks('eip155');
    ReownAppKitModalNetworks.removeTestNetworks();
    ReownAppKitModalNetworks.addSupportedNetworks('eip155', [
      ReownAppKitModalNetworkInfo(
        name: 'Celo',
        chainId: '42220',
        currency: 'CELO',
        rpcUrl: 'https://forno.celo.org',
        explorerUrl: 'https://explorer.celo.org/mainnet',
      ),
    ]);

    if (environment == Environment.testing) {
      ReownAppKitModalNetworks.addSupportedNetworks('eip155', [celoAlfajores]);
    }

    print("Web3 app and service initialized");
  }

  Future<ReownAppKitModal> initializeModal(BuildContext context) async {
    if (_modalInitialized) {
      return _appKitModal;
    }

    _appKitModal = ReownAppKitModal(
      context: context,
      appKit: appKit,
      includedWalletIds: includedWalletIds,
      /* requiredNamespaces: requiredNamespaces, */
    );

    await _appKitModal.init();

    await _appKitModal.selectChain(environment == Environment.production ? celoMainnet : celoAlfajores);

    _modalInitialized = true;
    return _appKitModal;
  }

  void _onConnection(ModalConnect? event) {
    if (event?.session.getAddress("eip155") != null) {
      connectedAddress = event!.session.getAddress("eip155")!;
      appKitModal.onModalConnect.unsubscribe(_onConnection);
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
