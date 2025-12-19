class ApiRoutes {
  static String baseUrl                  = 'https://oxfordonline.com.br/API/v1/';
  static String login                    = 'User/login';
  static String loginRegister            = 'User/register';
  static String products                 = 'Oxford/Products';
  static String productsSearch           = 'Product/AppSearch';
  static String appProduct               = 'Product/AppProduct';
  static String productImage             = 'Image/ProductImage';
  static String productImageUpdate       = 'Image/ReplaceProductImages';
  static String productImageUpdateBase64 = 'Image/ReplaceProductImages/Base64';
  static String productTag               = 'Tag';

  // Rotas para o filtro de atributos
  static String brands                = 'Brand';
  static String linesByBrand          = 'Lines/ByBrand';
  static String decorationByBrandLine = 'Decoration/ByBrandLine';

  // Rotas para o filtro de atributos de pallet
  static String pallets                = 'Pallet';
  static String palletItems            = 'Pallet/Item';
  static String allPalletItems         = 'Pallet/AllItems';
  static String palletImages           = 'Pallet/Image';
  static String palletSearch           = 'Pallet/Search';
  static String palletSearchItem       = 'Pallet/SearchItem';
  static String palletStatus           = 'Pallet/Status';

  // Rotas para GET e SET das cargas
  static String palletLoad             = 'PalletLoad';
  static String palletLoadUp           = 'PalletLoad/UpdateLoadStatus';
  static String palletLoadLine         = 'PalletLoad/Pallets';
  static String palletLoadReceiveLine  = 'PalletLoad/ReceiveItems';
  static String palletLoadInvoices     = 'PalletLoad/Invoices/Load';
  static String palletLoadInvoice      = 'PalletLoad/Invoice';

  // Rotas para GET e SET de imagens no FTP
  static String ftpGetImage              = 'Ftp/Images/GetBase64';
  static String ftpSetImage              = 'Ftp/Images/SetBase64';
  static String ftpDelImage              = 'Ftp/Images';

  // Rotas para o INVENTÁRIO
  static String inventory             = 'Inventory';

}
