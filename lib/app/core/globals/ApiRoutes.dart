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

  // Rotas para GET e SET de imagens no FTP
  static String ftpImage              = 'Ftp/Images/Base64';

}
