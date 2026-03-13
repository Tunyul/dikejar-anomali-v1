const products = require('../utils/products');

exports.getAllProducts = (req, res) => {
    res.json(products);
};
